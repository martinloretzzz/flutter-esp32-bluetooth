# Flutter Esp32 Bluetooth Template

Changes in android/ [1 if you take the code to an other project, 2 still nessesarely]:

1. Change minSdkVersion from 16 to 19 in android/app/build.gradle on line 42
2. Add implementation "androidx.core:core:1.1.0" to the Flutter_Blue Plugin in ~/flutter/.pub-cache/hosted/pub.dartlang.org/flutter_blue-0.6.3+1/android/build.gradle on line 80 like described here: https://github.com/pauldemarco/flutter_blue/issues/402#issuecomment-548081305

You need to give the location and change bluetooth connectivity permission to the app
