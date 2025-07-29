#!/usr/bin/env python3
"""
Simplified HTTP server for EditNova API endpoints
Works with Python standard library only (WebContainer compatible)
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

class EditNovaHandler(BaseHTTPRequestHandler):
    def _set_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    
    def do_OPTIONS(self):
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()
    
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/api/usage':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            
            response_data = {
                "active_users": 1203,
                "premium_users": 205,
                "background_removed": 540,
                "files_scanned": 134,
                "threats_blocked": 3
            }
            self.wfile.write(json.dumps(response_data).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode()) if post_data else {}
        except json.JSONDecodeError:
            data = {}
        
        if parsed_path.path == '/api/toggle-feature':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            
            feature = data.get('feature', 'unknown')
            enabled = data.get('enabled', False)
            response_data = {
                "status": "success", 
                "message": f"{feature} set to {enabled}"
            }
            self.wfile.write(json.dumps(response_data).encode())
            
        elif parsed_path.path == '/api/login':
            username = data.get('username', '')
            password = data.get('password', '')
            
            if username == "admin" and password == "editnova2025":
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self._set_cors_headers()
                self.end_headers()
                
                response_data = {
                    "status": "success", 
                    "token": "fake-jwt-token"
                }
                self.wfile.write(json.dumps(response_data).encode())
            else:
                self.send_response(401)
                self.send_header('Content-type', 'application/json')
                self._set_cors_headers()
                self.end_headers()
                
                response_data = {
                    "status": "error", 
                    "message": "Invalid credentials"
                }
                self.wfile.write(json.dumps(response_data).encode())
        
        elif parsed_path.path == '/api/create-poster':
            theme = data.get('theme', 'default')
            response_data = {
                "status": "success", 
                "message": f"Poster created with theme: {theme}"
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode())

        elif parsed_path.path == '/api/generate-art':
            description = data.get('description', 'abstract')
            response_data = {
                "status": "success", 
                "message": f"AI art generated for description: {description}"
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode())

        elif parsed_path.path == '/api/translate-text':
            text = data.get('text', '')
            language = data.get('language', 'en')
            response_data = {
                "status": "success", 
                "message": f"Text translated to {language}: {text}"
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

def run_server():
    server_address = ('', 5001)
    httpd = HTTPServer(server_address, EditNovaHandler)
    print("EditNova API Server starting on port 5001...")
    print("Available endpoints:")
    print("  GET  /api/usage")
    print("  POST /api/toggle-feature")
    print("  POST /api/login")
    print("  POST /api/create-poster")
    print("  POST /api/generate-art")
    print("  POST /api/translate-text")
    print("Server running at http://localhost:5001")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()