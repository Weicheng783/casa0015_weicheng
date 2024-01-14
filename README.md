# Story Trail App

![Story Trail App](assets/story_trail.png)

Welcome to Story Trail, an innovative mobile app that allows users to share their memories and photos by geotagging based on real locations. Explore the world around you and discover the stories hidden in every corner.

## About

Story Trail gives users the ability to share their memories and photos by geotagging them based on real locations. Other users can explore these memories by walking nearby, unlocking a unique and immersive experience. The app includes features such as user account management for saving exploration history, photo sharing based on real locations, and the ability to explore memories shared by others.

- **Author:** Weicheng
- **Collaboration:** Weicheng collaborated with ChatGPT and the GPT-3.5 model to create this unique experience.
- **Technology Stack:** Written entirely in Dart and developed using Flutter.

## Features

- **Geotagging Memories:** Share memories and photos by geotagging them to real locations.
- **Explore Nearby Memories:** Unlock and explore memories by walking near their geotagged locations.
- **User Account Management:** Save exploration history and manage your account for a personalized experience.
- **Photo Sharing:** Share and explore memories through photos linked to real-world locations.

## Installation

To install and run the Story Trail app, follow these steps:

1. Clone the repository: `git clone https://github.com/Weicheng783/casa0015_weicheng.git`
2. Navigate to the project directory: `cd casa0015_weicheng`
3. Install dependencies: `flutter pub get`
4. Run the app: `flutter run` or `flutter run --release` on iOS devices

Make sure you have Flutter and Dart installed on your machine. For more information, visit [Flutter](https://flutter.dev/docs/get-started/install).

## License

This project is licensed under the [MIT License](LICENSE.md).

## Presentation Video

[//]: # (Watch our presentation video to see Story Trail in action! [Presentation Video]&#40;link/to/video&#41;)

## Contact Details

Feel free to reach out if you have any questions or want to contribute to the app:

- **Weicheng:** [LinkedIn](https://github.com/Weicheng783)
- **ChatGPT:** [OpenAI](https://www.openai.com/)

Your feedback and contributions are highly appreciated! 🚀📱😄

## Dependencies

The Story Trail app relies on the following packages:

```yaml
dependencies:
  dynamic_color: ^1.4.0
  google_maps_flutter: ^2.0.10
  location: ^5.0.3
  sensors_plus: ^4.0.2
  http: ^1.1.2
  connectivity_plus: ^5.0.2
  shared_preferences: ^2.2.2
  vibration: ^1.8.4
  audioplayers: ^5.2.1
  image_picker: ^1.0.7
  restart_app: ^1.2.1
  photo_view: ^0.14.0
  url_launcher: ^6.2.3
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^2.0.0