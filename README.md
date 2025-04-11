<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Chaty

Chaty is a Firebase-powered chat widget designed for seamless integration into Flutter applications. It provides a robust and customizable chat interface with features like real-time messaging, media sharing, and notifications.

## Features

- **Real-time Messaging**: Send and receive messages instantly using Firebase Firestore.
- **Media Sharing**: Share images, videos, audio, and documents.
- **Push Notifications**: Get notified of new messages even when the app is in the background.
- **Customizable UI**: Easily customize chat bubbles, input fields, and more.
- **Typing Indicators**: Show when the other user is typing.
- **Unread Message Count**: Keep track of unread messages.
- **Message Deletion**: Delete messages with confirmation.
- **Cross-Platform Support**: Works on Android, iOS, Web, and Desktop.

## Getting Started

### Prerequisites

1. Ensure you have Flutter installed. Follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install).
2. Set up a Firebase project and enable Firestore.

### Setting Up Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click on **Add Project** and follow the steps to create a new project.
3. Once the project is created, navigate to the **Project Settings**.
4. Under the **General** tab, add your app:
   - For Android, download the `google-services.json` file and place it in the `android/app` directory.
   - For iOS, download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory.
5. Enable Firestore:
   - Go to the **Firestore Database** section in the Firebase Console.
   - Click on **Create Database**.
   - Choose a **Start in production mode** or **Start in test mode** based on your requirements.
   - Select a Cloud Firestore location and click **Enable**.

### Installation

1. Add Chaty to your `pubspec.yaml`:
   ```yaml
   dependencies:
     chaty: ^1.0.0
   ```
2. Run the following command to install the package:
   ```sh
   flutter pub get
   ```

## Usage

To integrate Chaty into your Flutter app:

1. Import the necessary components:
   ```dart
   import 'package:chaty/ui/chat_screen.dart';
   import 'package:chaty/models/message.dart';
   ```
2. Use the `ChatScreen` widget:
   ```dart
   ChatScreen(
     senderId: 'user1',
     receiverId: 'user2',
     mediaUploaderFunction: (mediaPath) async {
       // function that upload the mediapath and return the URL
       return 'uploaded_media_url';
     },
   );
   ```

For more examples, check the `/example` folder.

## Example

Here is a minimal example to get started:

```dart
import 'package:flutter/material.dart';
import 'package:chaty/ui/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(
        senderId: 'user1',
        receiverId: 'user2',
        mediaUploaderFunction: (mediaPath) async {
          // Simulate media upload
          return 'uploaded_media_url';
        },
      ),
    );
  }
}
```

## Additional Information

- **Contributing**: Contributions are welcome! Feel free to submit issues or pull requests.
- **License**: This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
- **Support**: For any issues or feature requests, please open an issue on [GitHub](github.com/mindsterapps/chaty/issues).

Happy coding!
