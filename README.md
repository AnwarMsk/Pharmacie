# Dwaya - Pharmacy Finder App

<p align="center">
  <img src="assets/images/logo.png" alt="Dwaya Logo" width="200"/>
</p>

Dwaya is a Flutter-based mobile application that helps users find nearby pharmacies, view pharmacy details, save favorites, and get directions to their chosen pharmacy.

## Features

- **Pharmacy Search**: Find pharmacies near your location or in specific areas
- **Detailed Information**: View pharmacy contact details, opening hours, and available services
- **Favorites**: Save your favorite pharmacies for quick access
- **Directions**: Get directions to pharmacies using map integration
- **User Profiles**: Create and manage your user profile
- **Offline Support**: Access basic features even without an internet connection
- **Multilingual Support**: Available in multiple languages (English, Arabic)

## Technologies Used

- **Flutter**: Cross-platform UI toolkit
- **Firebase**: Authentication, Cloud Firestore, and Analytics
- **Provider**: State management
- **Google Maps API**: Location services and maps integration
- **Connectivity Plus**: Network connectivity monitoring
- **Cached Network Image**: Efficient image loading and caching
- **Flutter Secure Storage**: Secure data storage

## Getting Started

### Prerequisites

- Flutter (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase account for backend services
- Google Maps API key

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/dwaya_app.git
   ```

2. Navigate to the project directory:
   ```
   cd dwaya_app
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Configure Firebase:
   - Create a Firebase project
   - Add your Android & iOS apps to the Firebase project
   - Download and add the google-services.json and GoogleService-Info.plist files to the respective directories
   - Enable Authentication and Firestore in the Firebase console

5. Configure Google Maps API:
   - Obtain a Google Maps API key
   - Add the API key to the appropriate files:
     - Android: android/app/src/main/AndroidManifest.xml
     - iOS: ios/Runner/AppDelegate.swift

6. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── firebase_options.dart     # Firebase configuration
├── initializers/             # Platform-specific initialization
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # API and backend services
├── utils/                    # Utility classes
└── widgets/                  # Reusable UI components
```

## Performance Optimizations

- **Caching System**: Uses SharedPreferences for persistent storage of API responses
- **Error Handling**: Comprehensive error reporting system
- **Offline Support**: ConnectivityHelper for network status monitoring
- **Image Optimization**: CachedNetworkImage for efficient image loading
- **Security**: Flutter Secure Storage for sensitive data
- **Input Validation**: Robust validation utilities

## Security

The app implements several security measures:
- Secure storage for sensitive user data
- Input validation to prevent injection attacks
- Proguard rules for Android to obfuscate code
- Firebase Authentication for secure user management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Flutter team for the amazing framework
- Firebase for backend services
- All the open-source packages used in this project
