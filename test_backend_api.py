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
    provider_unconfigured = path in {"/api/generate-art", "/api/translate-text", "/api/ocr-extract", "/api/social-share"}
    premium_requires_auth = path == "/api/upgrade-premium"
    feature_requires_auth = path == "/api/toggle-feature"
    batch_requires_auth = path == "/api/batch-process"
    binary_required = path in {"/api/upload-image", "/api/process-image", "/api/remove-background"}
    scan_without_bytes = path == "/api/scan-file"
    expected_status = 503 if provider_unconfigured else 401 if batch_requires_auth or feature_requires_auth else 200 if premium_requires_auth else 400 if binary_required or scan_without_bytes else 200
    assert response.status_code == expected_status
    assert response.is_json
    expected_result = "error" if provider_unconfigured or binary_required or batch_requires_auth or feature_requires_auth or scan_without_bytes else "success"
    assert response.get_json().get("status") == expected_result or path == "/api/health"


@pytest.mark.parametrize(
    "path,payload",
    [
        ("/api/login", {}),
        ("/api/signup", {"username": "x", "email": "x", "password": "short"}),
        ("/api/generate-art", {}),
        ("/api/translate-text", {}),
        ("/api/ocr-extract", {}),
    ],
)
def test_api_rejects_invalid_payload(client, path, payload):
    response = client.post(path, json=payload)
    assert response.status_code == 400
    assert response.is_json
    assert response.get_json()["status"] == "error"


def test_batch_rejects_unimplemented_convert_operation(client):
    auth = client.post(
        "/api/signup",
        json={"username": "convert-user", "email": "convert@example.com", "password": "strongpass123"},
    )
    response = client.post(
        "/api/batch-process",
        json={"fileIds": ["file-1"], "operation": "convert"},
        headers={"Authorization": f"Bearer {auth.get_json()['token']}"},
    )
    assert response.status_code == 400
    assert response.get_json() == {"status": "error", "message": "unsupported batch operation"}


def test_batch_rejects_invalid_payload_after_authentication(client):
    auth = client.post(
        "/api/signup",
        json={"username": "invalid-batch", "email": "invalid-batch@example.com", "password": "strongpass123"},
    )
    response = client.post(
        "/api/batch-process",
        json={"fileIds": [], "operation": "resize"},
        headers={"Authorization": f"Bearer {auth.get_json()['token']}"},
    )
    assert response.status_code == 400
    assert response.get_json()["status"] == "error"


def test_create_poster_returns_a_real_png_artifact(client):
    import base64

    response = client.post(
        "/api/create-poster",
        json={"theme": "neon", "text": "EditNova release"},
    )
    body = response.get_json()
    assert response.status_code == 200
    assert body["status"] == "success"
    assert body["mimeType"] == "image/png"
    assert body["width"] == 1200
    assert body["height"] == 1500
    assert base64.b64decode(body["imageData"]).startswith(b"\x89PNG\r\n\x1a\n")


def test_toggle_feature_requires_auth_and_persists_value(client):
    unauthenticated = client.post(
        "/api/toggle-feature",
        json={"feature": "notifications", "enabled": True},
    )
    assert unauthenticated.status_code == 401

    auth = client.post(
        "/api/signup",
        json={"username": "settings-user", "email": "settings@example.com", "password": "strongpass123"},
    )
    headers = {"Authorization": f"Bearer {auth.get_json()['token']}"}
    response = client.post(
        "/api/toggle-feature",
        json={"feature": "notifications", "enabled": False},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.get_json()["enabled"] is False
    with _database() as connection:
        stored = connection.execute(
            "SELECT enabled FROM feature_flags WHERE feature = ?",
            ("notifications",),
        ).fetchone()
    assert stored["enabled"] == 0


def test_social_share_reports_unconfigured_provider_instead_of_fake_success(client):
    response = client.post(
        "/api/social-share",
        json={"platform": "instagram", "imageId": "image-1"},
    )
    assert response.status_code == 503
    assert response.get_json() == {
        "status": "error",
        "message": "social sharing provider is not configured",
    }


def test_generate_art_rejects_malformed_provider_response(client, monkeypatch):
    monkeypatch.setenv("OPENAI_API_KEY", "test-key")
    from app import _provider_request

    monkeypatch.setattr("app._provider_request", lambda *args, **kwargs: {"data": None})
    response = client.post(
        "/api/generate-art",
        json={"description": "mountains", "style": "watercolor"},
    )
    assert response.status_code == 502
    assert response.get_json() == {"status": "error", "message": "AI art provider failed"}


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


def test_batch_processing_completes_for_uploaded_image(client):
    from PIL import Image

    auth = client.post(
        "/api/signup",
        json={"username": "batch-user", "email": "batch@example.com", "password": "strongpass123"},
    )
    headers = {"Authorization": f"Bearer {auth.get_json()['token']}"}
    image = Image.new("RGB", (8, 8), (20, 80, 180))
    stream = BytesIO()
    image.save(stream, format="PNG")
    stream.seek(0)

    uploaded = client.post(
        "/api/upload-image",
        data={"file": (stream, "batch-source.png")},
        content_type="multipart/form-data",
        headers=headers,
    )
    assert uploaded.status_code == 200
    image_id = uploaded.get_json()["imageId"]

    batch = client.post(
        "/api/batch-process",
        json={"fileIds": [image_id], "operation": "resize"},
        headers=headers,
    )
    body = batch.get_json()
    assert batch.status_code == 200
    assert body["state"] == "completed"
    assert body["queued"] is False
    assert len(body["outputs"]) == 1

    job = client.get(f"/api/jobs/{body['jobId']}", headers=headers)
    assert job.status_code == 200
    assert job.get_json()["job"]["state"] == "completed"


def test_users_cannot_access_each_others_files_or_batch_inputs(client):
    from PIL import Image

    owner = client.post(
        "/api/signup",
        json={"username": "owner", "email": "owner@example.com", "password": "strongpass123"},
    )
    other = client.post(
        "/api/signup",
        json={"username": "other", "email": "other@example.com", "password": "strongpass123"},
    )
    owner_headers = {"Authorization": f"Bearer {owner.get_json()['token']}"}
    other_headers = {"Authorization": f"Bearer {other.get_json()['token']}"}

    image = Image.new("RGB", (8, 8), (20, 80, 180))
    stream = BytesIO()
    image.save(stream, format="PNG")
    stream.seek(0)
    uploaded = client.post(
        "/api/upload-image",
        data={"file": (stream, "private.png")},
        content_type="multipart/form-data",
        headers=owner_headers,
    )
    file_id = uploaded.get_json()["imageId"]

    assert client.get(f"/api/files/{file_id}", headers=other_headers).status_code == 404
    batch = client.post(
        "/api/batch-process",
        json={"fileIds": [file_id], "operation": "resize"},
        headers=other_headers,
    )
    assert batch.status_code == 422
    assert batch.get_json()["status"] == "error"
    assert batch.get_json()["state"] == "failed"
    assert batch.get_json()["outputs"] == []
