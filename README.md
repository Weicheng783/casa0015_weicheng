# Story Trail App

![Story Trail App](assets/story_trail.png)

Welcome to Story Trail, an innovative cross-platform mobile app that allows users to share their memories and photos by geotagging based on real locations. Explore the world around you and discover the stories hidden in every corner.

![Story Trail Showcase](assets/ad1.jpg)

## About

Story Trail gives users the ability to share their memories and photos by geotagging them based on real locations. Other users can explore these memories by walking nearby, unlocking a unique and immersive experience. The app includes features such as user account management for saving exploration history, photo sharing based on real locations, and the ability to explore memories shared by others.

- **Author:** Weicheng
- **Collaboration:** Weicheng collaborated with ChatGPT and the GPT-3.5 model to create this unique experience.
- **Technology Stack:** Written entirely in Dart and developed using Flutter.

## UI Design

The Story Trail app follows a visually appealing design language:

### Android
The app utilizes Material3 UI design language on Android devices, providing a modern and consistent user experience.

Learn Material Design (MD-Google): https://m3.material.io/

### iOS
On iOS-based devices, Story Trail adheres to the Human Interface Guidelines and incorporates Cupertino styled widgets, ensuring a seamless and native feel for iOS users.

Learn Human Interface Guidelines (HIG-Apple): https://developer.apple.com/design/human-interface-guidelines

## Features

- **Geotagging Memories:** Share memories and photos by geotagging them to real locations.
- **Explore Nearby Memories:** Unlock and explore memories by walking near their geotagged locations.
- **User Account Management:** Save exploration history and manage your account for a personalized experience.
- **Photo Sharing:** Share and explore memories through photos linked to real-world locations.
- **Gemini Insights:** Get weather specific guidance by asking real data on Gemini.

## Installation

To install and run the Story Trail app, follow these steps:

1. Clone the repository: `git clone https://github.com/Weicheng783/casa0015_weicheng.git`
2. Navigate to the project directory: `cd casa0015_weicheng`
3. Change the file name AndroidManifest_CHANGE.xml to AndroidManifest.xml, your own configuration will be git-ignored.
4. For iOS builds, change the file in ios/Runner/AppDelegate_CHANGE.swift to AppDelegate.swift.
5. Install dependencies: `flutter pub get`.
6. For Android, add your Google Map Api Key of value to the file android/app/src/main/AndroidManifest.xml in the field of com.google.android.geo.API_KEY. For iOS, add it in ios/Runner/AppDelegate.swift.
7. Run the app: `flutter run` for debug or `flutter run --release` on iOS devices (this enables Desktop launch).

Make sure you have Flutter and Dart installed on your machine. For more information, visit [Flutter](https://flutter.dev/docs/get-started/install).

## License

This project is licensed under the [MIT License](LICENSE.md).

## Presentation Video

[//]: # (Watch our presentation video to see Story Trail in action! [Presentation Video](link/to/video))

## Contact Details

Feel free to reach out if you have any questions or want to contribute to the app:

- **Weicheng:** [GitHub](https://github.com/Weicheng783)
- **ChatGPT:** [OpenAI](https://www.openai.com/)
- **Chat Samples**: https://chat.openai.com/share/a7a6bf19-d9d7-419a-8451-01ee862afea2, https://chat.openai.com/share/cc3055a7-351d-4df4-bbce-7fe59d642e6a, https://chat.openai.com/share/5f15fa4c-7582-4ae8-89b1-7ce6b7c9d7e0
- if you want to see other chat histories, please contact me.

Your feedback are highly appreciated! 🚀📱😄

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
  flutter_exif_rotation: ^0.5.1
  device_info_plus: ^9.1.1
  image: ^4.1.4
  exif: ^3.3.0
  camera: ^0.10.5+9
  image_gallery_saver: ^2.0.3
  riverpod: ^2.5.0
  fl_chart: ^0.66.2
  flutter:
    sdk: flutter
  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.2
  corbado_auth: ^2.0.4
  flutter_hooks: ^0.20.5
  flutter_riverpod: ^2.4.10
  auth: ^8.2.0
  passkeys: ^2.0.4
  firebase_auth: ^4.17.4

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^2.0.0