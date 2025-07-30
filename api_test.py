#!/usr/bin/env python3
"""
EditNova API Comprehensive Test Suite
Tests all available API endpoints
"""

import requests
import json
import time

API_BASE = 'http://localhost:5001'

def test_api_endpoint(method, endpoint, data=None, expected_status=200):
    """Test a single API endpoint"""
    url = f"{API_BASE}{endpoint}"
    print(f"\n{'='*60}")
    print(f"Testing: {method} {endpoint}")
    print(f"{'='*60}")
    
    try:
        if method == 'GET':
            response = requests.get(url)
        elif method == 'POST':
            response = requests.post(url, json=data, headers={'Content-Type': 'application/json'})
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == expected_status:
            print("✅ Status: PASSED")
        else:
            print("❌ Status: FAILED")
        
        # Pretty print JSON response
        try:
            response_json = response.json()
            print(f"Response: {json.dumps(response_json, indent=2)}")
        except:
            print(f"Response: {response.text}")
            
        return response.status_code == expected_status
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def run_comprehensive_tests():
    """Run all API tests"""
    print("🚀 EditNova API Comprehensive Test Suite")
    print("="*80)
    
    test_results = []
    
    # Test GET endpoints
    test_results.append(test_api_endpoint('GET', '/api/usage'))
    test_results.append(test_api_endpoint('GET', '/api/templates'))
    test_results.append(test_api_endpoint('GET', '/api/achievements'))
    test_results.append(test_api_endpoint('GET', '/api/user/profile'))
    
    # Test POST endpoints
    test_results.append(test_api_endpoint('POST', '/api/login', {
        'username': 'admin',
        'password': 'editnova2025'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/signup', {
        'username': 'testuser',
        'email': 'test@editnova.com',
        'password': 'testpass123'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/toggle-feature', {
        'feature': 'ai_art',
        'enabled': True
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/upload-image', {
        'filename': 'test_image.jpg',
        'size': 2048000
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/process-image', {
        'operation': 'enhance',
        'imageId': 'test-image-123'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/remove-background', {
        'imageId': 'test-bg-image-456'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/scan-file', {
        'filename': 'document.pdf'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/generate-art', {
        'description': 'cyberpunk city at night',
        'style': 'digital'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/create-poster', {
        'theme': 'modern',
        'text': 'EditNova Test Poster'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/translate-text', {
        'text': 'Hello world',
        'sourceLang': 'en',
        'targetLang': 'es'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/generate-qr', {
        'text': 'https://editnova.com',
        'type': 'url'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/ocr-extract', {
        'imageId': 'test-ocr-image-789'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/batch-process', {
        'fileIds': ['file1', 'file2', 'file3'],
        'operation': 'resize'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/social-share', {
        'platform': 'instagram',
        'imageId': 'share-image-123'
    }))
    
    test_results.append(test_api_endpoint('POST', '/api/upgrade-premium', {
        'plan': 'monthly'
    }))
    
    # Test summary
    print("\n" + "="*80)
    print("📊 TEST SUMMARY")
    print("="*80)
    
    passed = sum(test_results)
    total = len(test_results)
    success_rate = (passed / total) * 100
    
    print(f"Total Tests: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")
    print(f"Success Rate: {success_rate:.1f}%")
    
    if success_rate == 100:
        print("\n🎉 ALL TESTS PASSED! EditNova API is fully operational!")
    elif success_rate >= 80:
        print("\n✅ Most tests passed. API is largely functional.")
    else:
        print("\n⚠️ Several tests failed. Check the API server.")
    
    return success_rate

if __name__ == "__main__":
    run_comprehensive_tests()