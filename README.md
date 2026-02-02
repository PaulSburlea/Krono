# Krono - Daily Photo Journal

Krono is a high-performance, offline-first daily photo journal application built with Flutter. It enables users to capture daily memories through photography, mood tracking, and automated metadata enrichment while maintaining strict data privacy through local-only storage.

## Core Features

- **Daily Photo Journaling:** Capture or import one significant moment per day to build a visual timeline.
- **Mood Tracking:** Log emotional states using a 5-point scale with visual indicators.
- **Metadata Enrichment:** Automated retrieval of precise location (Geolocator) and real-time weather data (OpenWeatherMap API) for each entry.
- **Biometric Security:** Secure access using device-native authentication (Fingerprint/Face ID) via `local_auth`.
- **Data Portability:**
    - Export journal entries to high-quality PDF documents.
    - Full local backup and restore system using ZIP archiving.
- **Internationalization:** Full support for English, Romanian, and French.
- **Theming:** Dynamic accent color selection with system-aware Dark Mode support.

## Technical Architecture

The project follows a modular Clean Architecture pattern, ensuring separation of concerns and testability:

- `lib/src/core`: Shared infrastructure including database configuration, service initializers, and global utilities.
- `lib/src/features`: Domain-specific modules (Journal, Settings, Streak, Stats).
    - `data`: Repository implementations and Data Transfer Objects (DTOs).
    - `domain`: Business logic and entities.
    - `presentation`: UI components and Riverpod providers for state management.

## Technical Stack

- **Framework:** Flutter (SDK >=3.5.0)
- **State Management:** Riverpod (Functional and Class-based Notifiers)
- **Database:** Drift (Reactive persistence over SQLite)
- **Security:** Local Auth (Biometrics)
- **Notifications:** Flutter Local Notifications (Scheduled reminders)
- **Backend Integration:**
    - Firebase Auth (Anonymous authentication)
    - Firebase Crashlytics (Fatal error reporting)
    - Firebase Analytics (Usage metrics)
- **Utilities:**
    - `geolocator` & `geocoding` for location services.
    - `flutter_image_compress` for background isolate image processing.
    - `pdf` & `printing` for document generation.

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio / Xcode
- A valid OpenWeatherMap API Key (configured in `WeatherService`)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/PaulSburlea/Krono.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code for Drift and Mockito:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Privacy & Security

Krono is designed with a privacy-first mindset. All personal data, including journal notes, photos, and location tags, are stored exclusively in the local SQLite database. No personal content is transmitted to external servers. Firebase services are utilized strictly for anonymous authentication and application stability monitoring.

## License

This project is licensed under the MIT License.