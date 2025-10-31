# SafeDrive

SafeDrive is a Flutter application designed to help drivers stay alert by detecting signs of drowsiness and distraction. The
project leverages on-device intelligence powered by Firebase ML Kit, keeping all processing local for better privacy and
responsiveness.

## Current status

This initial commit lays down the foundational Flutter structure inspired by the project specifications in
[`docs/Cahier_des_Charges.md`](docs/Cahier_des_Charges.md). It includes:

- Basic navigation across splash, home, detection, reports, settings, and about screens.
- Placeholder widgets for detection overlays and report summaries.
- Simple models to represent detection events and trip reports.
- A `SettingsProvider` to demonstrate state management with Provider.
- Service stubs ready for future Firebase ML Kit integrations.

## Getting started

1. Ensure the Flutter SDK (3.x) is installed locally.
2. From the repository root, run:

   ```bash
   flutter pub get
   flutter run
   ```

   The current build displays placeholder UI components until camera access and ML Kit services are implemented.

## Next steps

- Integrate the `camera` plugin to show the actual preview feed.
- Connect Firebase ML Kit face and object detection services.
- Persist trip reports and user preferences locally (Hive or SharedPreferences).
- Localize the interface using the language JSON files planned in the specification.
