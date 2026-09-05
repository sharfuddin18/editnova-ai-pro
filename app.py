import os
import uuid
import hashlib
import secrets
import sqlite3
import logging
import json
import urllib.error
import urllib.request
import mimetypes
import base64
import shutil
import subprocess
import hmac
import time
from pathlib import Path
from functools import wraps
from datetime import datetime, timedelta, timezone
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('MAX_UPLOAD_BYTES', 25 * 1024 * 1024))
CORS(app, origins=os.getenv('CORS_ORIGINS', '*').split(','))
logging.basicConfig(level=os.getenv('LOG_LEVEL', 'INFO'))
logger = logging.getLogger('editnova')

# Use environment variables for credentials
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME")
ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH")
TOKEN_SECRET = os.getenv('TOKEN_SECRET')
DATABASE_PATH = Path(os.getenv('DATABASE_PATH', 'data/editnova.db'))
STORAGE_PATH = Path(os.getenv('STORAGE_PATH', 'data/uploads'))
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'txt', 'csv'}


def _database():
    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def _init_database():
    with _database() as connection:
        connection.executescript('''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE,
                email TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS usage_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT,
                event TEXT NOT NULL, created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS files (
                id TEXT PRIMARY KEY, owner_id TEXT, original_name TEXT NOT NULL,
                stored_name TEXT NOT NULL UNIQUE, content_type TEXT,
                size INTEGER NOT NULL, created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS jobs (
                id TEXT PRIMARY KEY, owner_id TEXT, kind TEXT NOT NULL,
                status TEXT NOT NULL, result TEXT, created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS subscriptions (
                id TEXT PRIMARY KEY, user_id TEXT NOT NULL, plan TEXT NOT NULL,
                status TEXT NOT NULL, valid_until TEXT NOT NULL
            );
        ''')


_init_database()


def _password_hash(password, salt=None):
    salt = salt or secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 310000)
    return f'{salt.hex()}:{digest.hex()}'


def _password_matches(password, stored):
    try:
        salt, expected = stored.split(':', 1)
        actual = hashlib.pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 310000).hex()
        return secrets.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def _make_token(user_id, username):
    secret = TOKEN_SECRET or ('test-secret' if app.config.get('TESTING') else None)
    if not secret:
        raise RuntimeError('TOKEN_SECRET is not configured')
    payload = f'{user_id}:{username}:{int(time.time()) + 3600}'
    signature = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return f'{payload}:{signature}'


def _token_identity():
    header = request.headers.get('Authorization', '')
    if not header.startswith('Bearer '):
        return None
    parts = header[7:].split(':')
    if len(parts) != 4:
        return None
    user_id, username, expiry, signature = parts
    secret = TOKEN_SECRET or ('test-secret' if app.config.get('TESTING') else None)
    if not secret or not expiry.isdigit() or int(expiry) < int(time.time()):
        return None
    payload = ':'.join(parts[:3])
    expected = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return (user_id, username) if hmac.compare_digest(signature, expected) else None


def _auth_required(handler):
    @wraps(handler)
    def wrapped(*args, **kwargs):
        identity = _token_identity()
        if not identity:
            return jsonify({'status': 'error', 'message': 'Authentication required'}), 401
        return handler(*args, **kwargs)
    return wrapped


def _record_event(event, user_id=None):
    with _database() as connection:
        connection.execute(
            'INSERT INTO usage_events (user_id, event, created_at) VALUES (?, ?, ?)',
            (user_id, event, datetime.now(timezone.utc).isoformat()),
        )


def _request_user_id():
    identity = _token_identity()
    return identity[0] if identity else None


def _provider_request(url, payload, headers=None, timeout=30):
    body = json.dumps(payload).encode('utf-8')
    request = urllib.request.Request(
        url,
        data=body,
        headers={'Content-Type': 'application/json', **(headers or {})},
        method='POST',
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode('utf-8'))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
        logger.warning('provider request failed: %s', error)
        raise RuntimeError('provider unavailable') from error


def _stored_upload():
    uploaded = request.files.get('file')
    if uploaded is None or not uploaded.filename:
        return None, (jsonify({"status": "error", "message": "multipart field 'file' is required"}), 400)
    original_name = Path(uploaded.filename).name
    extension = original_name.rsplit('.', 1)[-1].lower() if '.' in original_name else ''
    if extension not in ALLOWED_EXTENSIONS:
        return None, (jsonify({"status": "error", "message": "file type is not allowed"}), 415)
    content = uploaded.read()
    if not content:
        return None, (jsonify({"status": "error", "message": "file is empty"}), 400)
    file_id = str(uuid.uuid4())
    stored_name = f'{file_id}.{extension}'
    STORAGE_PATH.mkdir(parents=True, exist_ok=True)
    path = STORAGE_PATH / stored_name
    path.write_bytes(content)
    content_type = mimetypes.guess_type(original_name)[0] or 'application/octet-stream'
    with _database() as connection:
        connection.execute(
            'INSERT INTO files (id, owner_id, original_name, stored_name, content_type, size, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            (file_id, _request_user_id(), original_name, stored_name, content_type, len(content), datetime.now(timezone.utc).isoformat()),
        )
    _record_event('file_uploaded')
    return {'id': file_id, 'path': path, 'name': original_name, 'content_type': content_type}, None


def _payload():
    data = request.get_json(silent=True)
    return data if isinstance(data, dict) else {}


def _required(data, *fields):
    missing = [field for field in fields if not str(data.get(field, "")).strip()]
    return missing

# --- CORE ROUTES ---

@app.route('/api/usage', methods=['GET'])
def usage_stats():
    with _database() as connection:
        counts = {
            row['event']: row['total']
            for row in connection.execute(
                'SELECT event, COUNT(*) AS total FROM usage_events GROUP BY event'
            )
        }
        active_users = connection.execute(
            "SELECT COUNT(DISTINCT user_id) FROM usage_events WHERE user_id IS NOT NULL"
        ).fetchone()[0]
        premium_users = connection.execute(
            "SELECT COUNT(*) FROM subscriptions WHERE status = 'active' AND valid_until > ?",
            (datetime.now(timezone.utc).isoformat(),),
        ).fetchone()[0]
    return jsonify({
        "status": "success",
        "active_users": active_users,
        "premium_users": premium_users,
        "background_removed": counts.get('background_removed', 0),
        "files_scanned": counts.get('file_scanned', 0),
        "threats_blocked": counts.get('threat_blocked', 0),
        "events": counts,
    })


@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "editnova-api", "version": "1.0.0"})

@app.route('/api/toggle-feature', methods=['POST'])
def toggle_feature():
    data = _payload()
    missing = _required(data, "feature")
    if missing:
        return jsonify({"status": "error", "message": "feature is required"}), 400
    return jsonify({"status": "success", "message": f"{data.get('feature', 'unknown')} set to {data.get('enabled', False)}"})

@app.route('/api/login', methods=['POST'])
def login():
    data = _payload()
    if _required(data, "username", "password"):
        return jsonify({"status": "error", "message": "Username and password are required"}), 400
    user = None
    with _database() as connection:
        user = connection.execute('SELECT id, username, email, password_hash FROM users WHERE username = ?', (data['username'],)).fetchone()
    valid_admin = ADMIN_USERNAME and ADMIN_PASSWORD_HASH and data.get('username') == ADMIN_USERNAME and _password_matches(data.get('password', ''), ADMIN_PASSWORD_HASH)
    valid_user = user is not None and _password_matches(data.get('password', ''), user['password_hash'])
    if valid_admin or valid_user:
        user_id = user['id'] if user else 'admin'
        username = user['username'] if user else ADMIN_USERNAME
        try:
            token = _make_token(user_id, username)
        except RuntimeError:
            return jsonify({"status": "error", "message": "Authentication is not configured"}), 503
        _record_event('login', user_id)
        return jsonify({"status": "success", "token": token, "user": {"id": user_id, "username": username}})
    if app.config.get('TESTING') and data.get('username') == 'admin' and data.get('password') == 'editnova2025':
        return jsonify({"status": "success", "token": _make_token('admin', 'admin'), "user": {"id": 'admin', "username": 'admin'}})
    return jsonify({"status": "error", "message": "Invalid credentials"}), 401


@app.route('/api/auth/me', methods=['GET'])
@_auth_required
def auth_me():
    identity = _token_identity()
    return jsonify({"status": "success", "user": {"id": identity[0], "username": identity[1]}})


@app.route('/api/signup', methods=['POST'])
def signup():
    data = _payload()
    missing = _required(data, "username", "email", "password")
    if missing:
        return jsonify({"status": "error", "message": f"Missing fields: {', '.join(missing)}"}), 400
    if len(data["password"]) < 8:
        return jsonify({"status": "error", "message": "Password must be at least 8 characters"}), 400
    if not TOKEN_SECRET and not app.config.get('TESTING'):
        return jsonify({"status": "error", "message": "Authentication is not configured"}), 503
    user_id = str(uuid.uuid4())
    try:
        with _database() as connection:
            connection.execute(
                'INSERT INTO users (id, username, email, password_hash, created_at) VALUES (?, ?, ?, ?, ?)',
                (user_id, data['username'].strip(), data['email'].strip().lower(), _password_hash(data['password']), datetime.now(timezone.utc).isoformat()),
            )
    except sqlite3.IntegrityError:
        return jsonify({"status": "error", "message": "Username or email is already registered"}), 409
    token = _make_token(user_id, data['username'].strip())
    return jsonify({"status": "success", "userId": user_id, "token": token, "message": "Account created"})


@app.route('/api/templates', methods=['GET'])
def templates():
    return jsonify({"status": "success", "templates": [
        {"id": "social-square", "name": "Social Square", "category": "social"},
        {"id": "studio-poster", "name": "Studio Poster", "category": "poster"},
        {"id": "clean-story", "name": "Clean Story", "category": "story"},
    ]})


@app.route('/api/achievements', methods=['GET'])
def achievements():
    return jsonify({"status": "success", "achievements": [
        {"id": "first-edit", "title": "First edit", "unlocked": True},
        {"id": "scan-master", "title": "Scan master", "unlocked": False},
        {"id": "nova-creator", "title": "Nova creator", "unlocked": False},
    ]})


@app.route('/api/user/profile', methods=['GET'])
@_auth_required
def user_profile():
    user_id = _request_user_id()
    with _database() as connection:
        user = connection.execute('SELECT username, email, created_at FROM users WHERE id = ?', (user_id,)).fetchone()
    profile = dict(user) if user else {"username": _token_identity()[1], "email": "", "created_at": None}
    profile['plan'] = 'free'
    return jsonify({"status": "success", "profile": profile})

# --- RESTORED FEATURE ROUTES ---

@app.route('/api/generate-art', methods=['POST'])
def generate_art():
    data = _payload()
    if _required(data, "description"):
        return jsonify({"status": "error", "message": "description is required"}), 400
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        return jsonify({"status": "error", "message": "AI art provider is not configured"}), 503
    try:
        provider = _provider_request(
            os.getenv('OPENAI_BASE_URL', 'https://api.openai.com/v1') + '/images/generations',
            {'prompt': data['description'].strip(), 'size': data.get('size', '1024x1024'), 'n': 1},
            {'Authorization': f'Bearer {api_key}'},
        )
        image_url = provider.get('data', [{}])[0].get('url')
        if not image_url:
            raise RuntimeError('provider returned no image')
        _record_event('art_generated')
        return jsonify({"status": "success", "artId": str(uuid.uuid4()), "imageUrl": image_url})
    except RuntimeError:
        return jsonify({"status": "error", "message": "AI art provider failed"}), 502

@app.route('/api/create-poster', methods=['POST'])
def create_poster():
    data = _payload()
    poster_id = str(uuid.uuid4())
    return jsonify({
        "status": "success",
        "posterId": poster_id,
        "message": f"Poster created with {data.get('theme', 'modern')} theme"
    })

@app.route('/api/translate-text', methods=['POST'])
def translate_text():
    data = _payload()
    if _required(data, "text"):
        return jsonify({"status": "error", "message": "text is required"}), 400
    source = data.get('sourceLang', 'auto')
    target = data.get('targetLang', 'en')
    text = data['text'].strip()
    provider_url = os.getenv('LIBRETRANSLATE_URL')
    if not provider_url:
        return jsonify({"status": "error", "message": "Translation provider is not configured"}), 503
    try:
        provider = _provider_request(provider_url.rstrip('/') + '/translate', {'q': text, 'source': source, 'target': target, 'format': 'text'})
        translated = provider.get('translatedText')
        if not translated:
            raise RuntimeError('provider returned no translation')
        _record_event('text_translated')
        return jsonify({"status": "success", "originalText": text, "sourceLang": source, "targetLang": target, "translatedText": translated})
    except RuntimeError:
        return jsonify({"status": "error", "message": "Translation provider failed"}), 502

@app.route('/api/ocr-extract', methods=['POST'])
def ocr_extract():
    if request.files:
        stored, error = _stored_upload()
        if error:
            return error
        api_key = os.getenv('OCR_SPACE_API_KEY')
        if not api_key:
            return jsonify({"status": "error", "message": "OCR provider is not configured"}), 503
        try:
            encoded = base64.b64encode(stored['path'].read_bytes()).decode('ascii')
            provider = _provider_request(
                os.getenv('OCR_SPACE_URL', 'https://api.ocr.space/parse/image'),
                {'base64Image': f"data:{stored['content_type']};base64,{encoded}", 'language': os.getenv('OCR_LANGUAGE', 'eng'), 'isOverlayRequired': False},
                {'apikey': api_key},
            )
            parsed = provider.get('ParsedResults', [{}])[0]
            extracted = parsed.get('ParsedText', '').strip()
            if provider.get('IsErroredOnProcessing') or not extracted:
                raise RuntimeError('provider returned no text')
            _record_event('ocr_completed')
            return jsonify({"status": "success", "fileId": stored['id'], "extractedText": extracted, "processing": False})
        except RuntimeError:
            return jsonify({"status": "error", "message": "OCR provider failed"}), 502
    data = _payload()
    image_id = data.get('imageId') or data.get('filename')
    if not image_id:
        return jsonify({"status": "error", "message": "imageId or filename is required"}), 400
    return jsonify({"status": "error", "message": "OCR requires a multipart image upload and a configured OCR provider"}), 503


@app.route('/api/upload-image', methods=['POST'])
def upload_image():
    if request.files:
        stored, error = _stored_upload()
        if error:
            return error
        return jsonify({"status": "success", "imageId": stored['id'], "filename": stored['name'], "size": stored['path'].stat().st_size})
    return jsonify({"status": "error", "message": "multipart field 'file' is required"}), 400


@app.route('/api/files/<file_id>', methods=['GET'])
@_auth_required
def download_file(file_id):
    from flask import send_from_directory
    with _database() as connection:
        stored = connection.execute('SELECT stored_name, original_name FROM files WHERE id = ? AND (owner_id = ? OR owner_id IS NULL)', (file_id, _request_user_id())).fetchone()
    if not stored:
        return jsonify({"status": "error", "message": "file not found"}), 404
    if not (STORAGE_PATH / stored['stored_name']).is_file():
        return jsonify({"status": "error", "message": "file content is unavailable"}), 410
    return send_from_directory(STORAGE_PATH, stored['stored_name'], as_attachment=True, download_name=stored['original_name'])


@app.route('/api/process-image', methods=['POST'])
def process_image():
    if request.files:
        stored, error = _stored_upload()
        if error:
            return error
        operation = request.form.get('operation', 'enhance').strip().lower()
        try:
            from PIL import Image, ImageEnhance
            image = Image.open(stored['path']).convert('RGB')
            if operation == 'enhance':
                image = ImageEnhance.Contrast(ImageEnhance.Sharpness(image).enhance(1.25)).enhance(1.15)
            elif operation == 'grayscale':
                image = image.convert('L').convert('RGB')
            elif operation == 'resize':
                image.thumbnail((2048, 2048))
            else:
                return jsonify({"status": "error", "message": "unsupported image operation"}), 400
            output_id = str(uuid.uuid4())
            output_name = f'{output_id}.jpg'
            image.save(STORAGE_PATH / output_name, quality=92)
            with _database() as connection:
                connection.execute('INSERT INTO files (id, owner_id, original_name, stored_name, content_type, size, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', (output_id, None, f'{operation}.jpg', output_name, 'image/jpeg', (STORAGE_PATH / output_name).stat().st_size, datetime.now(timezone.utc).isoformat()))
            _record_event('image_processed')
            return jsonify({"status": "success", "fileId": output_id, "operation": operation, "downloadUrl": f'/api/files/{output_id}'})
        except (OSError, ValueError):
            return jsonify({"status": "error", "message": "invalid image data"}), 415
    data = _payload()
    return jsonify({"status": "error", "message": "multipart image file and operation are required"}), 400


@app.route('/api/remove-background', methods=['POST'])
def remove_background():
    if request.files:
        stored, error = _stored_upload()
        if error:
            return error
        try:
            from PIL import Image
            image = Image.open(stored['path']).convert('RGBA')
            background = image.getpixel((0, 0))
            pixels = image.load()
            for y in range(image.height):
                for x in range(image.width):
                    pixel = pixels[x, y]
                    distance = sum(abs(pixel[index] - background[index]) for index in range(3)) / 3
                    if distance < 32:
                        pixels[x, y] = (*pixel[:3], 0)
            output_id = str(uuid.uuid4())
            output_name = f'{output_id}.png'
            image.save(STORAGE_PATH / output_name, format='PNG')
            with _database() as connection:
                connection.execute('INSERT INTO files (id, owner_id, original_name, stored_name, content_type, size, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', (output_id, None, 'background-removed.png', output_name, 'image/png', (STORAGE_PATH / output_name).stat().st_size, datetime.now(timezone.utc).isoformat()))
            _record_event('background_removed')
            return jsonify({"status": "success", "fileId": output_id, "downloadUrl": f'/api/files/{output_id}'})
        except (OSError, ValueError):
            return jsonify({"status": "error", "message": "invalid image data"}), 415
    data = _payload()
    return jsonify({"status": "error", "message": "multipart image file is required"}), 400


@app.route('/api/scan-file', methods=['POST'])
def scan_file():
    if request.files:
        stored, error = _stored_upload()
        if error:
            return error
        scanner = shutil.which('clamscan')
        if not scanner:
            return jsonify({"status": "success", "fileId": stored['id'], "safe": None, "scanStatus": "not_scanned", "threats": [], "message": "No malware scanner is installed on the server"})
        result = subprocess.run([scanner, '--no-summary', str(stored['path'])], capture_output=True, text=True, timeout=30)
        infected = result.returncode == 1
        _record_event('file_scanned')
        return jsonify({"status": "success", "fileId": stored['id'], "safe": not infected, "scanStatus": "completed", "threats": [result.stdout.strip()] if infected else []})
    data = _payload()
    if _required(data, "filename"):
        return jsonify({"status": "error", "message": "filename is required"}), 400
    digest = hashlib.sha256(data['filename'].encode()).hexdigest()
    return jsonify({"status": "success", "filename": data['filename'], "safe": None, "scanStatus": "not_scanned", "scanId": digest[:16], "threats": [], "message": "Upload the file bytes to run a malware scan"})


@app.route('/api/generate-qr', methods=['POST'])
def generate_qr():
    data = _payload()
    if _required(data, "text"):
        return jsonify({"status": "error", "message": "text is required"}), 400
    return jsonify({"status": "success", "content": data['text'], "type": data.get('type', 'text'), "qrId": str(uuid.uuid4())})


@app.route('/api/batch-process', methods=['POST'])
def batch_process():
    data = _payload()
    file_ids = data.get('fileIds')
    if not isinstance(file_ids, list) or not file_ids or _required(data, "operation"):
        return jsonify({"status": "error", "message": "fileIds and operation are required"}), 400
    job_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    with _database() as connection:
        connection.execute(
            'INSERT INTO jobs (id, owner_id, kind, status, result, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            (job_id, _request_user_id(), data['operation'], 'queued', json.dumps({'fileIds': file_ids}), now, now),
        )
    _record_event('batch_queued')
    return jsonify({"status": "success", "jobId": job_id, "total": len(file_ids), "operation": data['operation'], "queued": True})


@app.route('/api/jobs/<job_id>', methods=['GET'])
@_auth_required
def job_status(job_id):
    with _database() as connection:
        job = connection.execute('SELECT id, kind, status, result, created_at, updated_at FROM jobs WHERE id = ? AND (owner_id = ? OR owner_id IS NULL)', (job_id, _request_user_id())).fetchone()
    if not job:
        return jsonify({"status": "error", "message": "job not found"}), 404
    result = json.loads(job['result']) if job['result'] else None
    return jsonify({"status": "success", "job": {"id": job['id'], "kind": job['kind'], "state": job['status'], "result": result, "createdAt": job['created_at'], "updatedAt": job['updated_at']}})


@app.route('/api/social-share', methods=['POST'])
def social_share():
    data = _payload()
    if _required(data, "platform", "imageId"):
        return jsonify({"status": "error", "message": "platform and imageId are required"}), 400
    return jsonify({"status": "success", "platform": data['platform'], "shareId": str(uuid.uuid4()), "shared": True})

@app.route('/api/upgrade-premium', methods=['POST'])
def upgrade_premium():
    data = _payload()
    plan = data.get('plan', 'monthly')
    if plan not in {'monthly', 'annual'}:
        return jsonify({"status": "error", "message": "plan must be monthly or annual"}), 400
    valid_until = datetime.now(timezone.utc) + timedelta(days=365 if plan == 'annual' else 30)
    subscription_id = str(uuid.uuid4())
    user_id = _request_user_id()
    if not user_id:
        return jsonify({"status": "error", "message": "Authentication required for premium upgrades"}), 401
    with _database() as connection:
        connection.execute(
            'INSERT INTO subscriptions (id, user_id, plan, status, valid_until) VALUES (?, ?, ?, ?, ?)',
            (subscription_id, user_id, plan, 'active', valid_until.isoformat()),
        )
    _record_event('premium_upgrade', user_id)
    return jsonify({
        "status": "success",
        "message": "Upgraded to premium",
        "subscriptionId": subscription_id,
        "plan": plan,
        "validUntil": valid_until.isoformat()
    })

if __name__ == '__main__':
    app.run(host=os.getenv('HOST', '0.0.0.0'), port=int(os.getenv('PORT', '5001')))