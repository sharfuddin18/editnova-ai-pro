EditNova AI Pro - AI-Powered All-in-One Editor
EditNova AI Pro is an advanced, AI-driven editing suite designed for seamless media manipulation and content creation.

🚀 Project Status
Core Architecture: Flutter-based mobile frontend with Python/Flask backend.

AI Integration: Speech recognition and speech output use platform plugins. Nova currently responds with local keyword rules; no generative AI provider is configured.

UI/UX: Custom Montserrat typography system and animation assets integrated.

Frontend Status: Currently stabilizing asset compilation and dependency management for cross-platform deployment.

🛠 Tech Stack
Frontend: Flutter (Dart)

Backend: Python (Flask)

AI/ML: Integrated via API (Speech-to-Text, TTS, Lottie Animations)

Build Tools: Flutter SDK, Pip

⚙️ Development Environment Setup
Prerequisites
Flutter SDK: Ensure Flutter 3.0.0+ is installed and configured in your PATH.

Python: Version 3.8+ required for backend services.

OS: Development is currently optimized for local Windows environments.

Installation Steps
Clone the repository:

Bash
git clone [your-repo-link]
cd editnova-ai-pro
Setup Frontend (Flutter):

Bash
# Install dependencies
flutter pub get

# Clean build cache (if encountering asset path errors)
flutter clean
Setup Backend (Python):

Bash
pip install -r requirements.txt
python app.py

The Flutter app uses `http://10.0.2.2:5001` for the backend from an Android emulator and `http://localhost:5001` on web and desktop. For a physical device on a trusted local network, start Flask with `FLASK_HOST=0.0.0.0` and set `EDITNOVA_API_BASE_URL` to the development machine's LAN address when building. For deployment, use an HTTPS backend origin, for example `--dart-define=EDITNOVA_API_BASE_URL=https://api.example.com`. Cleartext HTTP is enabled only in Android debug builds.
📂 Asset Management
The project utilizes a specific directory structure for branding:

Fonts: Managed via pubspec.yaml using Montserrat-Regular and Montserrat-Bold.

Assets: Located in /assets/images/ and /assets/animations/ (Lottie).

Troubleshooting Assets: If you encounter Failed to load font errors, ensure your terminal is closed and perform a flutter clean to clear the cached asset bundle before re-running.

📡 API Endpoints
The backend provides the following interfaces:

GET /api/usage: Returns an unavailable response until an analytics data source is configured.

POST /api/toggle-feature: Returns an unavailable response for server-side settings; app preferences are stored locally.

POST /api/login: Admin authentication when ADMIN_USERNAME and ADMIN_PASSWORD are configured.

Provider-dependent routes for AI art, server-side translation/OCR, and premium upgrades return HTTP 503 until their respective providers are integrated. The Flutter app provides on-device Latin OCR and translation on Android/iOS, local poster creation, batch resize/format conversion, flat-color background removal, and image editing. Translation language models require an internet connection to download once, then run on-device. The local background remover is not AI segmentation. Security scanning remains unavailable; selected files are not treated as scanned or safe.

💡 Known Limitations
OneDrive Syncing: Asset loading may be affected by background OneDrive sync processes. It is recommended to work in a locally excluded folder if build speeds are slow.

Web Build: Currently optimized for mobile deployment (Android/iOS). Browser debugging via flutter run -d chrome may trigger platform-specific network exceptions if the backend is not actively reachable on the expected port.

Developed by Sharfuddin Ahmed | Version 1.0.0+1