# Flutter Task Manager

## Setup
1. Clone the repo
2. Run `flutter pub get`
3. Add your `google-services.json` to `android/app/`
4. Enable Email/Password auth in Firebase Console
5. Create Firestore database in test mode
6. Run `flutter run`

For Android, create the Firebase app with this package name unless you change it in Gradle:
`com.example.project_manager`.

## Firestore Rules
Publish the rules in `firestore.rules` from Firebase Console -> Firestore Database -> Rules.
They allow each signed-in user to manage only their own tasks under:
`users/{uid}/tasks/{taskId}`.

## Features
- Firebase Authentication (Sign Up / Login / Logout)
- Firestore CRUD (Add / Edit / Delete / Complete tasks)
- REST API motivational quotes
- Liquid glass UI, light mode

## Architecture
Provider + Service layer. Screens -> Providers -> Services -> Firebase/HTTP.
