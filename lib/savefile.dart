import 'dart:io';
import 'dart:math';

import 'package:open_file/open_file.dart' as open_file;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart'
    as path_provider_interface;

///To save the Excel file in the Mobile and Desktop platforms.
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';

Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    // Request permission
    status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  } else {
    return true;
  }
}

Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
  try {
    requestStoragePermission();
    final externalPath = (await path_provider.getDownloadsDirectory(/*type: path_provider.StorageDirectory.downloads*/));
    String picturesDirName = "Pictures";
    String extraDirectory = "excelsheets"+"/";



// Splitting the externalPath
    List<String> externalPathList = externalPath!.path.split('/');


// getting Position of 'Android'


//Joining the List<Strings> to generate the rootPath with "/" at the end.
    String rootPath = externalPathList.join('/');
    rootPath+="/";

//Creating Pictures Directory (if not exist)
    Directory picturesDir = Directory(rootPath+picturesDirName+"/"+extraDirectory);
    if (!picturesDir.existsSync()) {
      //Creating Directory
      await picturesDir.create(recursive: true);
      //Directory Created
    } else {
      //Directory Already Existed
    }

//Creating "app_name" Directory (if not exist)
    Directory appNameDir = Directory(rootPath+picturesDirName+"/"+extraDirectory);
    if (!appNameDir.existsSync()) {
      //Creating Directory
      await appNameDir.create(recursive: true);
      //Directory Created
    } else {
      //Directory Already Existed
    }

//Creating String varible to store the path where you want to save file.
    String fileSaveLocation = rootPath+picturesDirName+"/";

    final String filePath = '$fileSaveLocation/$fileName';

    final file =File(filePath);
    file.create(recursive: true);
    file.writeAsBytes(bytes);

print(file.path);
    if (await file.exists()) {
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, open the file directly
      // await open_file.OpenFile.open(filePath)
      // ;
        String sdf = file.path;
        await Share.shareFiles([sdf]);
        print(file.path);
      } else if (Platform.isWindows) {
        // For Windows, use 'start' command to open the file
        await Process.run('start', <String>[filePath], runInShell: true);
      } else if (Platform.isMacOS) {
        // For macOS, use 'open' command to open the file
        await Process.run('open', <String>[filePath], runInShell: true);
      } else if (Platform.isLinux) {
        // For Linux, use 'xdg-open' command to open the file
        await Process.run('xdg-open', <String>[filePath], runInShell: true);
      }
    } else {
      print('File does not exist.');
    }
  } catch (e) {
    print('Error: $e');
  }
}

/*
///To save the Excel file in the web platform.
Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
   AnchorElement(
       href:
       'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
      ..setAttribute('download', fileName)
      ..click();
}*/
String generateRandomString(int length) {
  final random = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
}