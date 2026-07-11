import os
import uuid
import random
from datetime import datetime, timedelta
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv

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
        "active_users": 1203,
        "premium_users": 205,
        "background_removed": 540,
        "files_scanned": 134,
        "threats_blocked": 3
    })

@app.route('/api/toggle-feature', methods=['POST'])
def toggle_feature():
    data = request.json or {}
    return jsonify({"status": "success", "message": f"{data.get('feature', 'unknown')} set to {data.get('enabled', False)}"})

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json or {}
    if data.get('username') == ADMIN_USERNAME and data.get('password') == ADMIN_PASSWORD:
        return jsonify({"status": "success", "token": "fake-jwt-token"})
    return jsonify({"status": "error", "message": "Invalid credentials"}), 401

# --- RESTORED FEATURE ROUTES ---

@app.route('/api/generate-art', methods=['POST'])
def generate_art():
    data = request.json or {}
    art_id = str(uuid.uuid4())
    return jsonify({
        "status": "success",
        "artId": art_id,
        "message": f"AI art generated: {data.get('description', 'abstract art')}",
        "imageUrl": f"ai_art_{art_id}.jpg"
    })

@app.route('/api/create-poster', methods=['POST'])
def create_poster():
    data = request.json or {}
    poster_id = str(uuid.uuid4())
    return jsonify({
        "status": "success",
        "posterId": poster_id,
        "message": f"Poster created with {data.get('theme', 'modern')} theme"
    })

@app.route('/api/translate-text', methods=['POST'])
def translate_text():
    data = request.json or {}
    return jsonify({
        "status": "success",
        "originalText": data.get('text', ''),
        "translatedText": "Translated Result" # Placeholder logic
    })

@app.route('/api/ocr-extract', methods=['POST'])
def ocr_extract():
    return jsonify({
        "status": "success",
        "extractedText": "Welcome to EditNova - AI-Powered Suite",
        "confidence": 98.5
    })

@app.route('/api/upgrade-premium', methods=['POST'])
def upgrade_premium():
    return jsonify({
        "status": "success", 
        "message": "Upgraded to premium",
        "validUntil": (datetime.now() + timedelta(days=30)).isoformat()
    })

if __name__ == '__main__':
    app.run(port=5001)