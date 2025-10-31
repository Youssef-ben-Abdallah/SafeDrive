# SafeDrive

SafeDrive is a Flutter application designed to help drivers stay alert by detecting signs of drowsiness and distraction. The
project leverages on-device intelligence powered by Firebase ML Kit, keeping all processing local for better privacy and
responsiveness.

## Current status

The application now integrates Firebase ML Kit to power both the front-facing drowsiness detector and the rear-facing
hazard detector. Key features include:

- Real-time driver monitoring that triggers alerts when the camera detects closed eyes or yawning.
- Rear camera object detection that warns about phones, pedestrians, and nearby vehicles.
- Audible and haptic alerts using native alarm and vibration APIs.
- Persistent alert logging and driving reports stored locally.
- Provider-based state management that keeps detection status in sync with the UI.

## Getting started

1. Ensure the Flutter SDK (3.x) is installed locally.
2. Create a Firebase project and enable the **ML Kit Face Detection** and **Object Detection & Tracking** APIs.
3. Add the Firebase configuration files to the Flutter project:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - (Optional) `macos/Runner/GoogleService-Info.plist` if you plan to run on macOS
4. Make sure the Android project applies the Google services Gradle plugin and that the iOS/macOS runners include the
   Firebase initialization code produced by `flutterfire configure`.
5. From the repository root, run:

   ```bash
   flutter pub get
   flutter run
   ```

   On the first launch the app will request camera permissions. Once granted, you can start a detection session from the
   home screen.

## Next steps

- Expand the alert system with customizable thresholds and UI feedback for each detection.
- Synchronize reports with a secure cloud backend for fleet monitoring scenarios.
- Localize the interface using the language JSON files planned in the specification.
- Add unit and widget tests that validate the ML decision logic with recorded camera frames.
