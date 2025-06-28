from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/api/usage')
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
    data = request.json
    # Save settings logic here
    return jsonify({"status": "success", "message": f"{data['feature']} set to {data['enabled']}"})

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    if data['username'] == "admin" and data['password'] == "editnova2025":
        return jsonify({"status": "success", "token": "fake-jwt-token"})
    return jsonify({"status": "error", "message": "Invalid credentials"}), 401

if __name__ == '__main__':
    app.run(port=5001)