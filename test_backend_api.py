import pytest
from io import BytesIO

from app import app, _database


@pytest.fixture()
def client():
    app.config.update(TESTING=True)
    with _database() as connection:
        connection.execute("DELETE FROM users")
        connection.execute("DELETE FROM usage_events")
    with app.test_client() as test_client:
        yield test_client


@pytest.mark.parametrize(
    "method,path,payload",
    [
        ("get", "/api/health", None),
        ("get", "/api/usage", None),
        ("get", "/api/templates", None),
        ("get", "/api/achievements", None),
        ("get", "/api/user/profile", None),
        ("post", "/api/signup", {"username": "new", "email": "new@example.com", "password": "password123"}),
        ("post", "/api/login", {"username": "admin", "password": "editnova2025"}),
        ("post", "/api/toggle-feature", {"feature": "ai_art", "enabled": True}),
        ("post", "/api/upload-image", {"filename": "photo.jpg", "size": 100}),
        ("post", "/api/process-image", {"operation": "enhance", "imageId": "image-1"}),
        ("post", "/api/remove-background", {"imageId": "image-1"}),
        ("post", "/api/scan-file", {"filename": "document.pdf"}),
        ("post", "/api/generate-art", {"description": "mountains"}),
        ("post", "/api/create-poster", {"theme": "modern", "text": "EditNova"}),
        ("post", "/api/translate-text", {"text": "Hello", "sourceLang": "en", "targetLang": "es"}),
        ("post", "/api/generate-qr", {"text": "https://example.com"}),
        ("post", "/api/ocr-extract", {"imageId": "image-1"}),
        ("post", "/api/batch-process", {"fileIds": ["image-1"], "operation": "resize"}),
        ("post", "/api/social-share", {"platform": "instagram", "imageId": "image-1"}),
        ("post", "/api/upgrade-premium", {"plan": "monthly"}),
    ],
)
def test_api_endpoint_returns_success(client, method, path, payload):
    headers = {}
    if path in {"/api/user/profile", "/api/upgrade-premium"}:
        auth = client.post("/api/signup", json={"username": "route-user", "email": "route@example.com", "password": "strongpass123"})
        headers["Authorization"] = f"Bearer {auth.get_json()['token']}"
    response = getattr(client, method)(path, json=payload, headers=headers)
    provider_unconfigured = path in {"/api/generate-art", "/api/translate-text", "/api/ocr-extract"}
    premium_requires_auth = path == "/api/upgrade-premium"
    binary_required = path in {"/api/upload-image", "/api/process-image", "/api/remove-background"}
    expected_status = 503 if provider_unconfigured else 200 if premium_requires_auth else 400 if binary_required else 200
    assert response.status_code == expected_status
    assert response.is_json
    expected_result = "error" if provider_unconfigured or binary_required else "success"
    assert response.get_json().get("status") == expected_result or path == "/api/health"


@pytest.mark.parametrize(
    "path,payload",
    [
        ("/api/login", {}),
        ("/api/signup", {"username": "x", "email": "x", "password": "short"}),
        ("/api/generate-art", {}),
        ("/api/translate-text", {}),
        ("/api/ocr-extract", {}),
        ("/api/batch-process", {"fileIds": [], "operation": "resize"}),
    ],
)
def test_api_rejects_invalid_payload(client, path, payload):
    response = client.post(path, json=payload)
    assert response.status_code == 400
    assert response.is_json
    assert response.get_json()["status"] == "error"


def test_signup_persists_hashed_password_and_returns_signed_token(client):
    response = client.post(
        "/api/signup",
        json={"username": "secure-user", "email": "secure@example.com", "password": "strongpass123"},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["token"]
    with _database() as connection:
        user = connection.execute("SELECT password_hash FROM users WHERE username = ?", ("secure-user",)).fetchone()
    assert user is not None
    assert user["password_hash"] != "strongpass123"
    assert ":" in user["password_hash"]
    identity = client.get("/api/auth/me", headers={"Authorization": f"Bearer {body['token']}"})
    assert identity.status_code == 200


def test_binary_upload_and_image_processing_create_downloadable_files(client):
    from PIL import Image

    auth = client.post("/api/signup", json={"username": "file-user", "email": "file@example.com", "password": "strongpass123"})
    headers = {"Authorization": f"Bearer {auth.get_json()['token']}"}
    image = Image.new("RGB", (8, 8), (255, 255, 255))
    image.putpixel((4, 4), (20, 80, 180))
    stream = BytesIO()
    image.save(stream, format="PNG")
    image_bytes = stream.getvalue()
    stream.seek(0)

    uploaded = client.post(
        "/api/upload-image",
        data={"file": (stream, "source.png")},
        content_type="multipart/form-data",
        headers=headers,
    )
    assert uploaded.status_code == 200
    image_id = uploaded.get_json()["imageId"]

    processed = client.post(
        "/api/process-image",
        data={"file": (BytesIO(image_bytes), "source.png"), "operation": "grayscale"},
        content_type="multipart/form-data",
        headers=headers,
    )
    assert processed.status_code == 200
    output_id = processed.get_json()["fileId"]
    download = client.get(f"/api/files/{output_id}", headers=headers)
    assert download.status_code == 200
    assert download.mimetype == "image/jpeg"

    removed = client.post(
        "/api/remove-background",
        data={"file": (BytesIO(image_bytes), "source.png")},
        content_type="multipart/form-data",
        headers=headers,
    )
    assert removed.status_code == 200
    assert client.get(f"/api/files/{removed.get_json()['fileId']}", headers=headers).mimetype == "image/png"
