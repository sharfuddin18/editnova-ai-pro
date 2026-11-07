import base64
import unittest
from unittest.mock import patch

from app import app


class LoginRouteTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_login_fails_when_admin_credentials_are_not_configured(self):
        with patch('app.ADMIN_USERNAME', None), patch('app.ADMIN_PASSWORD', None):
            response = self.client.post('/api/login', json={})

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json()['status'], 'error')

    def test_login_requires_both_credentials(self):
        with patch('app.ADMIN_USERNAME', 'admin'), patch('app.ADMIN_PASSWORD', 'secret'):
            response = self.client.post('/api/login', json={'username': 'admin'})

        self.assertEqual(response.status_code, 400)

    def test_login_rejects_invalid_credentials(self):
        with patch('app.ADMIN_USERNAME', 'admin'), patch('app.ADMIN_PASSWORD', 'secret'):
            response = self.client.post(
                '/api/login',
                json={'username': 'admin', 'password': 'wrong'},
            )

        self.assertEqual(response.status_code, 401)

    def test_login_returns_a_non_static_token_for_valid_credentials(self):
        credentials = {'username': 'admin', 'password': 'secret'}
        with patch('app.ADMIN_USERNAME', 'admin'), patch('app.ADMIN_PASSWORD', 'secret'):
            first_response = self.client.post('/api/login', json=credentials)
            second_response = self.client.post('/api/login', json=credentials)

        self.assertEqual(first_response.status_code, 200)
        self.assertNotEqual(first_response.get_json()['token'], 'fake-jwt-token')
        self.assertNotEqual(
            first_response.get_json()['token'],
            second_response.get_json()['token'],
        )


class ArtGenerationRouteTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_art_generation_does_not_claim_success_without_a_provider(self):
        response = self.client.post(
            '/api/generate-art',
            json={'description': 'a mountain lake', 'style': 'realistic'},
        )

        self.assertEqual(response.status_code, 503)
        payload = response.get_json()
        self.assertEqual(payload['status'], 'error')
        self.assertIn('provider is configured', payload['message'])
        self.assertNotIn('artId', payload)
        self.assertNotIn('imageUrl', payload)

    def test_usage_does_not_return_fabricated_totals(self):
        response = self.client.get('/api/usage')

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json()['status'], 'error')
        self.assertNotIn('active_users', response.get_json())

    def test_feature_toggle_does_not_claim_server_side_changes(self):
        response = self.client.post(
            '/api/toggle-feature',
            json={'feature': 'cloud_sync', 'enabled': True},
        )

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.get_json()['status'], 'error')

    def test_unconfigured_creation_translation_ocr_and_payment_routes_fail_honestly(self):
        requests = [
            ('/api/create-poster', {'theme': 'modern', 'text': 'Sample'}),
            ('/api/translate-text', {'text': 'Hello', 'targetLang': 'es'}),
            ('/api/ocr-extract', {'imageId': 'sample'}),
            ('/api/upgrade-premium', {'plan': 'monthly'}),
        ]

        for path, body in requests:
            with self.subTest(path=path):
                response = self.client.post(path, json=body)

                self.assertEqual(response.status_code, 503)
                self.assertEqual(response.get_json()['status'], 'error')
                self.assertNotIn('validUntil', response.get_json())


class QRGenerationRouteTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_qr_route_returns_a_real_png_image(self):
        response = self.client.post(
            '/api/generate-qr',
            json={'text': 'https://editnova.example', 'type': 'url'},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload['status'], 'success')
        image_bytes = base64.b64decode(payload['imageData'], validate=True)
        self.assertTrue(image_bytes.startswith(b'\x89PNG\r\n\x1a\n'))

    def test_qr_route_rejects_incomplete_urls(self):
        response = self.client.post(
            '/api/generate-qr',
            json={'text': 'editnova.example', 'type': 'url'},
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.get_json()['status'], 'error')

    def test_qr_route_supports_typed_payloads(self):
        payloads = [
            {'text': 'hello', 'type': 'text'},
            {'text': 'editor@example.com', 'type': 'email'},
            {'text': '+15551234567', 'type': 'phone'},
            {'text': 'StudioWifi|correct-horse-battery', 'type': 'wifi'},
            {'text': '+15551234567|Hello', 'type': 'sms'},
        ]

        for payload in payloads:
            with self.subTest(qr_type=payload['type']):
                response = self.client.post('/api/generate-qr', json=payload)
                self.assertEqual(response.status_code, 200)
                self.assertTrue(response.get_json()['imageData'])


if __name__ == '__main__':
    unittest.main()