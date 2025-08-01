# EditNova - AI-Powered Mobile App

## Environment Setup Issues

**Important Note:** This project is designed as a Flutter mobile application, but the current WebContainer environment has limitations:

### Current Environment Limitations:
- Flutter SDK is not available in WebContainer
- This is a browser-based Node.js runtime, not a full development environment
- Mobile app development requires native SDKs and emulators

### What's Working:
✅ **Backend API Server** - Flask server with all endpoints
✅ **Project Structure** - Complete Flutter project files
✅ **Dependencies** - All required packages defined in pubspec.yaml

### To Run This Project Locally:

1. **Install Flutter SDK:**
   ```bash
   # Download Flutter SDK from https://flutter.dev/docs/get-started/install
   # Add Flutter to your PATH
   flutter doctor
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install Python Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run Backend Server:**
   ```bash
   python app.py
   ```

5. **Run Flutter App:**
   ```bash
   flutter run
   ```

### Current WebContainer Capabilities:
- ✅ Backend API development and testing
- ✅ Code review and structure analysis
- ✅ Documentation and planning
- ❌ Flutter mobile app compilation
- ❌ Mobile device emulation

### API Endpoints Available:
- `GET /api/usage` - Usage statistics
- `POST /api/toggle-feature` - Feature toggles
- `POST /api/login` - Authentication

The Flask backend server is now running and ready to serve the mobile app when run in a proper Flutter development environment.