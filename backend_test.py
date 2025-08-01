#!/usr/bin/env python3
"""
EditNova Backend API Test Results
Comprehensive testing of all 19 API endpoints
"""

import requests
import json
import sys
from datetime import datetime

class EditNovaAPITester:
    def __init__(self, base_url="http://localhost:5001"):
        self.base_url = base_url
        self.tests_run = 0
        self.tests_passed = 0
        self.results = []

    def run_test(self, name, method, endpoint, expected_status, data=None):
        """Run a single API test"""
        url = f"{self.base_url}/{endpoint}"
        headers = {'Content-Type': 'application/json'}

        self.tests_run += 1
        print(f"\n🔍 Testing {name}...")
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=headers)
            elif method == 'POST':
                response = requests.post(url, json=data, headers=headers)

            success = response.status_code == expected_status
            if success:
                self.tests_passed += 1
                print(f"✅ Passed - Status: {response.status_code}")
            else:
                print(f"❌ Failed - Expected {expected_status}, got {response.status_code}")

            # Store result
            self.results.append({
                "name": name,
                "method": method,
                "endpoint": endpoint,
                "status_code": response.status_code,
                "success": success,
                "response": response.json() if success else response.text
            })

            return success, response.json() if success else {}

        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            self.results.append({
                "name": name,
                "method": method,
                "endpoint": endpoint,
                "status_code": 0,
                "success": False,
                "error": str(e)
            })
            return False, {}

    def run_comprehensive_tests(self):
        """Run all EditNova API tests"""
        print("🚀 EditNova Backend API Comprehensive Test Suite")
        print("=" * 60)
        
        # GET Endpoints
        self.run_test("Usage Statistics", "GET", "api/usage", 200)
        self.run_test("Design Templates", "GET", "api/templates", 200)
        self.run_test("User Achievements", "GET", "api/achievements", 200)
        self.run_test("User Profile", "GET", "api/user/profile", 200)
        
        # Authentication
        self.run_test("Admin Login", "POST", "api/login", 200, {
            'username': 'admin',
            'password': 'editnova2025'
        })
        
        self.run_test("User Signup", "POST", "api/signup", 200, {
            'username': 'testuser',
            'email': 'test@editnova.com',
            'password': 'testpass123'
        })
        
        # Feature Management
        self.run_test("Toggle Feature", "POST", "api/toggle-feature", 200, {
            'feature': 'ai_art',
            'enabled': True
        })
        
        # Image Processing
        self.run_test("Image Upload", "POST", "api/upload-image", 200, {
            'filename': 'test_image.jpg',
            'size': 2048000
        })
        
        self.run_test("Image Processing", "POST", "api/process-image", 200, {
            'operation': 'enhance',
            'imageId': 'test-image-123'
        })
        
        self.run_test("Background Removal", "POST", "api/remove-background", 200, {
            'imageId': 'test-bg-image-456'
        })
        
        # AI Features
        self.run_test("AI Art Generation", "POST", "api/generate-art", 200, {
            'description': 'cyberpunk city at night',
            'style': 'digital'
        })
        
        self.run_test("Poster Creation", "POST", "api/create-poster", 200, {
            'theme': 'modern',
            'text': 'EditNova Test Poster'
        })
        
        # Utility Features
        self.run_test("File Security Scan", "POST", "api/scan-file", 200, {
            'filename': 'document.pdf'
        })
        
        self.run_test("Text Translation", "POST", "api/translate-text", 200, {
            'text': 'Hello world',
            'sourceLang': 'en',
            'targetLang': 'es'
        })
        
        self.run_test("QR Code Generation", "POST", "api/generate-qr", 200, {
            'text': 'https://editnova.com',
            'type': 'url'
        })
        
        self.run_test("OCR Text Extraction", "POST", "api/ocr-extract", 200, {
            'imageId': 'test-ocr-image-789'
        })
        
        # Advanced Features
        self.run_test("Batch Processing", "POST", "api/batch-process", 200, {
            'fileIds': ['file1', 'file2', 'file3'],
            'operation': 'resize'
        })
        
        self.run_test("Social Media Share", "POST", "api/social-share", 200, {
            'platform': 'instagram',
            'imageId': 'share-image-123'
        })
        
        self.run_test("Premium Upgrade", "POST", "api/upgrade-premium", 200, {
            'plan': 'monthly'
        })

    def print_summary(self):
        """Print test results summary"""
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        
        success_rate = (self.tests_passed / self.tests_run) * 100
        
        print(f"Total Tests: {self.tests_run}")
        print(f"Passed: {self.tests_passed}")
        print(f"Failed: {self.tests_run - self.tests_passed}")
        print(f"Success Rate: {success_rate:.1f}%")
        
        if success_rate == 100:
            print("\n🎉 ALL TESTS PASSED! EditNova API is fully operational!")
        elif success_rate >= 80:
            print("\n✅ Most tests passed. API is largely functional.")
        else:
            print("\n⚠️ Several tests failed. Check the API server.")
        
        return success_rate

def main():
    """Main test execution"""
    tester = EditNovaAPITester()
    
    print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    tester.run_comprehensive_tests()
    success_rate = tester.print_summary()
    
    # Return appropriate exit code
    return 0 if success_rate == 100 else 1

if __name__ == "__main__":
    sys.exit(main())