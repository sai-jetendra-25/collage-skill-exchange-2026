# College Skill Exchange

A Flutter-based peer-to-peer skill sharing platform for college students.

## Live Demo
https://skill-exchange-457f3.web.app

## Overview
College Skill Exchange helps students discover classmates who can teach skills they want to learn. Students can create profiles, list skills they can teach and want to learn, discover potential matches, send exchange requests, communicate, and build their learning network.

## Main Features
- Student registration and login UI
- Student profiles
- Can Teach / Want to Learn skills
- Student discovery and search
- Skill matching
- Exchange requests
- Accept / decline requests
- Chat / exchange communication
- Projects and experience
- Ratings and endorsements
- Firebase configuration
- Flutter Web deployment with Firebase Hosting

## Technology Stack
- Flutter
- Dart
- Firebase Core
- Firebase Hosting
- FlutterFire CLI
- Git & GitHub
- SharedPreferences for local prototype data

## Basic Architecture
```text
Flutter Application
       |
       +-- UI / Screens
       +-- Student Profiles
       +-- Skill Matching
       +-- Exchange Requests
       +-- Chat / Ratings
       |
       +-- Firebase
              +-- Firebase Configuration
              +-- Firebase Hosting
```

## Run Locally
```bash
git clone https://github.com/sai-jetendra-25/collage-skill-exchange-2026.git
cd collage-skill-exchange-2026
flutter pub get
flutter run
```

For Chrome:
```bash
flutter run -d chrome
```

## Build and Deploy
```bash
flutter build web
firebase deploy --only hosting
```

## Project Structure
```text
lib/
├── main.dart
└── firebase_options.dart

android/
ios/
macos/
web/
windows/

firebase.json
.firebaserc
pubspec.yaml
```

## Future Enhancements
- College-email verification
- Firebase Authentication
- Cloud Firestore
- Real-time chat
- Push notifications
- Advanced skill recommendations
- Exchange scheduling
- Admin dashboard
- Student reputation system

## Repository
https://github.com/sai-jetendra-25/collage-skill-exchange-2026

## License
Developed as a college project for educational purposes.
