EditNova AI Pro - AI-Powered All-in-One Editor
EditNova AI Pro is an advanced, AI-driven editing suite designed for seamless media manipulation and content creation.

🚀 Project Status
Core Architecture: Flutter-based mobile frontend with Python/Flask backend.

AI Integration: Voice-to-text, Text-to-speech, and generative AI features are implemented.

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
📂 Asset Management
The project utilizes a specific directory structure for branding:

Fonts: Managed via pubspec.yaml using Montserrat-Regular and Montserrat-Bold.

Assets: Located in /assets/images/ and /assets/animations/ (Lottie).

Troubleshooting Assets: If you encounter Failed to load font errors, ensure your terminal is closed and perform a flutter clean to clear the cached asset bundle before re-running.

📡 API Endpoints
The backend provides the following interfaces:

GET /api/usage: Retrieve current AI token usage.

POST /api/toggle-feature: Toggle specific AI editing capabilities.

POST /api/login: Secure user authentication.

💡 Known Limitations
OneDrive Syncing: Asset loading may be affected by background OneDrive sync processes. It is recommended to work in a locally excluded folder if build speeds are slow.

Web Build: Currently optimized for mobile deployment (Android/iOS). Browser debugging via flutter run -d chrome may trigger platform-specific network exceptions if the backend is not actively reachable on the expected port.

Developed by Sharfuddin Ahmed | Version 1.0.0+1