import os
import random
import secrets
import hmac
import base64
import io
import re
from urllib.parse import urlparse
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
import qrcode

# Load variables from the .env file
load_dotenv()

app = Flask(__name__)
CORS(app)

# Use environment variables for credentials
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")

# --- CORE ROUTES ---

@app.route('/api/usage', methods=['GET'])
def usage_stats():
    return jsonify({
        "status": "error",
        "message": "Usage statistics are unavailable because no analytics data source is configured."
    }), 503

@app.route('/api/toggle-feature', methods=['POST'])
def toggle_feature():
    return jsonify({
        "status": "error",
        "message": "Server-side feature management is unavailable; settings are stored locally in the app."
    }), 503

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    if not ADMIN_USERNAME or not ADMIN_PASSWORD:
        return jsonify({
            "status": "error",
            "message": "Admin login is not configured"
        }), 503

    username = data.get('username')
    password = data.get('password')
    if not isinstance(username, str) or not isinstance(password, str) or not username or not password:
        return jsonify({"status": "error", "message": "Username and password are required"}), 400

    if hmac.compare_digest(username, ADMIN_USERNAME) and hmac.compare_digest(password, ADMIN_PASSWORD):
        return jsonify({"status": "success", "token": secrets.token_urlsafe(32)})
    return jsonify({"status": "error", "message": "Invalid credentials"}), 401

# --- RESTORED FEATURE ROUTES ---

@app.route('/api/generate-art', methods=['POST'])
def generate_art():
    return jsonify({
        "status": "error",
        "message": "AI art generation is unavailable because no image-generation provider is configured."
    }), 503

@app.route('/api/create-poster', methods=['POST'])
def create_poster():
    return jsonify({
        "status": "error",
        "message": "Poster creation is unavailable because no design service is configured."
    }), 503

@app.route('/api/translate-text', methods=['POST'])
def translate_text():
    return jsonify({
        "status": "error",
        "message": "Translation is unavailable because no translation service is configured."
    }), 503

@app.route('/api/ocr-extract', methods=['POST'])
def ocr_extract():
    return jsonify({
        "status": "error",
        "message": "Text extraction is unavailable because no OCR service is configured."
    }), 503

@app.route('/api/upgrade-premium', methods=['POST'])
def upgrade_premium():
    return jsonify({
        "status": "error",
        "message": "Premium upgrades are unavailable because no payment provider is configured."
    }), 503

def _build_qr_payload(content, qr_type):
    if qr_type == 'url':
        parsed = urlparse(content)
        if parsed.scheme not in ('http', 'https') or not parsed.netloc:
            raise ValueError('Enter a complete http or https URL.')
        return content
    if qr_type == 'text':
        return content
    if qr_type == 'email':
        address = content[7:] if content.lower().startswith('mailto:') else content
        if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', address):
            raise ValueError('Enter a valid email address.')
        return f'mailto:{address}'
    if qr_type == 'phone':
        if not re.fullmatch(r'[+0-9(). -]{3,32}', content) or sum(char.isdigit() for char in content) < 3:
            raise ValueError('Enter a valid phone number.')
        return f'tel:{content}'
    if qr_type == 'wifi':
        if '|' not in content:
            raise ValueError('Enter WiFi details as network name|password.')
        ssid, password = content.split('|', 1)
        if not ssid or not password:
            raise ValueError('WiFi network name and password are required.')
        escape = lambda value: re.sub(r'([\\;,:\"])', r'\\\1', value)
        return f'WIFI:T:WPA;S:{escape(ssid)};P:{escape(password)};;'
    if qr_type == 'sms':
        if '|' not in content:
            raise ValueError('Enter SMS details as phone number|message.')
        phone, message = content.split('|', 1)
        if not re.fullmatch(r'[+0-9(). -]{3,32}', phone):
            raise ValueError('Enter a valid phone number before the | separator.')
        return f'SMSTO:{phone}:{message}'
    raise ValueError('Unsupported QR code type.')

@app.route('/api/generate-qr', methods=['POST'])
def generate_qr():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"status": "error", "message": "A JSON request body is required."}), 400

    content = data.get('text')
    qr_type = data.get('type', 'text')
    if not isinstance(content, str) or not content.strip() or len(content) > 2048:
        return jsonify({"status": "error", "message": "Content must be between 1 and 2048 characters."}), 400
    if not isinstance(qr_type, str):
        return jsonify({"status": "error", "message": "Unsupported QR code type."}), 400

    try:
        payload = _build_qr_payload(content.strip(), qr_type.lower())
        code = qrcode.QRCode(
            version=None,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=8,
            border=4,
        )
        code.add_data(payload)
        code.make(fit=True)
        image = code.make_image(fill_color='black', back_color='white')
        output = io.BytesIO()
        image.save(output, format='PNG')
    except ValueError as error:
        return jsonify({"status": "error", "message": str(error)}), 400
    except qrcode.exceptions.DataOverflowError:
        return jsonify({"status": "error", "message": "Content is too long to encode as a QR code."}), 400

    return jsonify({
        "status": "success",
        "imageData": base64.b64encode(output.getvalue()).decode('ascii'),
        "mimeType": "image/png",
    })

if __name__ == '__main__':
    app.run(
        host=os.getenv('FLASK_HOST', '127.0.0.1'),
        port=int(os.getenv('PORT', '5001')),
    )