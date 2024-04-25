import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:csv_read/database_function/hive_function.dart';
import 'package:csv_read/database_function/hive_model.dart';
import 'package:csv_read/screens/data_table_screen.dart';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
const apiKey = '5cb33542-c2b9-4c29-84fd-8b0a2955927c';
void main() async {
  await Hive.initFlutter();
  await HiveService().initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

/*  Future<void> readCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist.');
        return;
      }

      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(convertEmptyTo: ''))
          .toList();

      // Process fields as needed
      print(fields);
    } catch (e) {
      print('Error reading CSV file: $e');
      // Handle error appropriately
    }
  }
  Future<List<String>> getColumnData(String filePath, int columnIndex) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist.');
        return [];
      }

      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      // Extract the column data
      final List<String> columnData = [];
      for (final row in fields) {
        if (row.length > columnIndex) {
          columnData.add(row[columnIndex].toString());
        } else {
          // Handle case where columnIndex exceeds row length
          columnData.add('');
        }
      }

      return columnData;
    } catch (e) {
      print('Error reading CSV file: $e');
      // Handle error appropriately
      return [];
    }
  }*/

/*  void getCSVNames({required File filePath, required String sheetName}) async{
    if (!filePath.existsSync()) {
      print('File does not exist at path: ${filePath.path}');
      return;
    }

    try {
      if(filePath.existsSync()) {
        var bytes = filePath.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        print(excel.sheets[sheetName]!.maxRows);

        final element = excel.sheets[sheetName]!;

        for (var data in element.selectRange(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
            end: CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: excel.sheets[sheetName]!.maxRows - 1))) {
          if (data != null) {
            for (var value in data) {
              if (value != null) {
                setState(() {
                  csvList.add(value.value.toString());
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error reading Excel file: $e');
      // Handle error appropriately
    }
  }*/
  File? fileName;

  List<String> csvList = [];
  List<String> multipleResponses = [];
  final sheetNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 50,
              ),
              GestureDetector(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['xlsx'],
                          allowMultiple: false);

                  if (result != null) {
                    File file = File(result.files.single.path!);
                    var bytes = file.readAsBytesSync();
                    var excel = Excel.decodeBytes(bytes);

                    String sheetName = excel.sheets.keys.toList()[0];
                    print(excel.sheets[sheetName]!.maxRows);
                    final element = excel.sheets[sheetName]!;
                    csvList.clear();
                    for (var data in element.selectRange(
                        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
                        end: CellIndex.indexByColumnRow(
                            columnIndex: 0,
                            rowIndex: excel.sheets[sheetName]!.maxRows - 1))) {
                      if (data != null) {
                        for (var value in data) {
                          Future.wait([]);
                          if (value != null) {
                            setState(() {
                              csvList.add(value.value.toString());
                            });
                          }
                        }
                      }
                    }
                    setState(() {
                      csvList.removeWhere((element) => element.toLowerCase().contains('false'));
                      fileName = file;
                    });

                    List<String> apiUrls = List<String>.from(
                      csvList.map(
                        (e) =>
                            'https://api.company-information.service.gov.uk/search?q=$e&items_per_page=1&start_index=1',
                      ),
                    );
                    List<String> responses =
                        await hitApiRequestsInBatches(apiUrls, 10);
                    setState(() {
                      multipleResponses = responses;
                    });
                  } else {}
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 50),
                    child: Text(
                      'Pick Your File',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              fileName == null
                  ? const SizedBox()
                  : Text('${csvList.length} record(s) found'),
              const SizedBox(
                height: 50,
              ),
              dataLoading == true
                  ? const CircularProgressIndicator()
                  : const SizedBox(),
              const SizedBox(
                height: 20,
              ),
              multipleResponses.isEmpty
                  ? const SizedBox()
                  : Text('${multipleResponses.length} APIs record(s) found'),
              const SizedBox(
                height: 20,
              ),
              multipleResponses.isEmpty
                  ? const SizedBox()
                  : GestureDetector(
                      onTap: () {
                        companyData.clear();
                        for (int i = 0; i < csvList.length; i++) {

                 if(csvList[i].toLowerCase() != 'false'){

                   String companyName = csvList[i];
                   print(multipleResponses[i]);
                   ComapnyDetailsModelModel? model =
                   multipleResponses[i].isEmpty
                       ? null
                       : ComapnyDetailsModelModel.fromJson(
                     jsonDecode(
                       multipleResponses[i],
                     ),
                   );

                   setState(() {
                     companyData.add(InitialCompanyData(companyName: companyName, companyData: model));
                   });
                 }
                        }


                        Navigator.push(context, MaterialPageRoute(builder: (context)=> DataTableClass(dataList: companyData)));

                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 50),
                          child: Text(
                            'Convert List of data into Table',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
              companyData.isEmpty
                  ? const SizedBox()
                  : Text(
                      '${companyData.length} APIs record(s) converted into List'),
            ],
          ),
        ),
      ),
    );
  }

  List<InitialCompanyData> companyData = [];
  bool dataLoading = false;
  final dio = Dio();



  /*Future<List<String>> hitApiRequestsInBatches(
      List<String> urls, int batchSize) async {
    List<String> responses = [];

    // Split the URLs into batches
    for (int i = 0; i < urls.length; i += batchSize) {
      List<String> batchUrls = urls.sublist(
          i, i + batchSize < urls.length ? i + batchSize : urls.length);

      // Send requests for the current batch in parallel
      List<Future<String>> batchFutures = batchUrls
          .map((url) => dio
              .get(url,
                  options: Options(headers: {
                    "Authorization":
                        'Basic ${base64Encode(utf8.encode('$apiKey:'))}'
                  }))
              .then((value) => value.data.toString()))
          .toList();

      // Wait for all requests in the current batch to complete
      List<String> batchResponses = await Future.wait(batchFutures);

      // Add the responses from the current batch to the list of all responses
      responses.addAll(batchResponses);
    }

    return responses;
  }*/

  Future<List<String>> hitApiRequestsInBatches(
    List<String> urls,
    int batchSize,
  ) async {
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    setState(() {
      dataLoading = true;
    });
    List<String> responses = [];
    print('Basic ${base64Encode(utf8.encode('$apiKey:'))}');

    // Split the URLs into batches
    for (int i = 0; i < urls.length; i += batchSize) {
      List<String> batchUrls = urls.sublist(
          i, i + batchSize < urls.length ? i + batchSize : urls.length);

      // Send requests for the current batch in parallel
      List<Future<String>> batchFutures = batchUrls.map((url) async {

        try {
          final response = await retry(
            // Make a GET request
            () => http.get(Uri.parse(url), headers: {
              "Authorization": 'Basic ${base64Encode(utf8.encode('$apiKey:'))}'
            }).timeout(const Duration(seconds: 30)),

            onRetry: (reason) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Retrying. Error Occurred\n${reason.toString()}')));
            },
            // Retry on SocketException or TimeoutException
            retryIf: (e) => e is SocketException || e is TimeoutException,
          );

          final company = Company(companyName: url.split('q=')[1].split('&')[0], companyDetails: response.body);

         await HiveService().addCompany(company);


          return response.body;
        } catch (e) {
          // Handle exception, for example, log it
          print('Error occurred while fetching data: $e');
          // Return an empty string or some placeholder value
          return '';
        }
      }).toList();

      // Wait for all requests in the current batch to complete
      List<String> batchResponses = await Future.wait(batchFutures);


      // Add the responses from the current batch to the list of all responses
      responses.addAll(batchResponses);
      print('Total responses received: ${responses.length}');
    }
    setState(() {
      dataLoading = false;
    });
    stopwatch.stop();
    log("Time taken by All the ${urls.length} APIs ${stopwatch.elapsed.inMinutes}");
    return responses;
  }

}

class InitialCompanyData {
  final String companyName;
  final ComapnyDetailsModelModel? companyData;

  InitialCompanyData({required this.companyName, this.companyData});
}

class ComapnyDetailsModelModel {
  final int pageNumber;
  final int itemsPerPage;
  final String kind;
  final int startIndex;
  final List<Item2> items;
  final int totalResults;

  ComapnyDetailsModelModel({
    required this.pageNumber,
    required this.itemsPerPage,
    required this.kind,
    required this.startIndex,
    required this.items,
    required this.totalResults,
  });

  factory ComapnyDetailsModelModel.fromRawJson(String str) =>
      ComapnyDetailsModelModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ComapnyDetailsModelModel.fromJson(Map<String, dynamic> json) =>
      ComapnyDetailsModelModel(
        pageNumber: json["page_number"],
        itemsPerPage: json["items_per_page"],
        kind: json["kind"],
        startIndex: json["start_index"],
        items:json["items"] == null||json["items"].isEmpty?[]: List<Item2>.from(json["items"].map((x) => Item2.fromJson(x))),
        totalResults: json["total_results"],
      );

  Map<String, dynamic> toJson() => {
        "page_number": pageNumber,
        "items_per_page": itemsPerPage,
        "kind": kind,
        "start_index": startIndex,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "total_results": totalResults,
      };
}

class Item2 {
  final String companyNumber;
  final String description;
  final String addressSnippet;
  final String companyStatus;
  final String snippet;
  final String kind;
  final String dateOfCreation;
  // final List<String> descriptionIdentifier;
  final Address address;
  final String companyType;
  final String title;



  Item2({
    required this.companyNumber,
    required this.description,
    required this.addressSnippet,
    required this.companyStatus,
    required this.snippet,
    required this.kind,
    required this.dateOfCreation,
    // required this.descriptionIdentifier,
    required this.address,
    required this.companyType,
    required this.title,
  });

  factory Item2.fromRawJson(String str) => Item2.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Item2.fromJson(Map<String, dynamic> json) => Item2(
        companyNumber: json["company_number"]??'',
        description: json["description"]??'',
        addressSnippet: json["address_snippet"]??'',
        companyStatus: json["company_status"]??'',
        snippet: json["snippet"]??'',
        kind: json["kind"]??'',
        dateOfCreation: json["date_of_creation"]??'',
        // descriptionIdentifier:
        // json["description_identifier"]==null?[]:List<String>.from((json["description_identifier"] == null?[]:json["description_identifier"]).map((x) => x)),
        address: Address.fromJson(json["address"]??{"address": {
        "postal_code": "",
        "locality": "",
        "premises": "",
        "country": "",
        "address_line_1": ""
        }}),
        companyType: json["company_type"]??'',
        title: json["title"]??'',
      );

  Map<String, dynamic> toJson() => {
        "company_number": companyNumber,
        "description": description,
        "address_snippet": addressSnippet,
        "company_status": companyStatus,
        "snippet": snippet,
        "kind": kind,
        "date_of_creation":
            "${dateOfCreation}",
        // "description_identifier":
        //     List<dynamic>.from(descriptionIdentifier.map((x) => x)),
        "address": address.toJson(),
        "company_type": companyType,
        "title": title,

      };
}

class Address {
  final String postalCode;
  final String locality;
  final String premises;
  final String country;
  final String addressLine1;

  Address({
    required this.postalCode,
    required this.locality,
    required this.premises,
    required this.country,
    required this.addressLine1,
  });

  factory Address.fromRawJson(String str) => Address.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        postalCode: json["postal_code"]??'',
        locality: json["locality"]??'',
        premises: json["premises"]??'',
        country: json["country"]??'',
        addressLine1: json["address_line_1"]??'',
      );

  Map<String, dynamic> toJson() => {
        "postal_code": postalCode,
        "locality": locality,
        "premises": premises,
        "country": country,
        "address_line_1": addressLine1,
      };
}

class Links {
  final String self;

  Links({
    required this.self,
  });

  factory Links.fromRawJson(String str) => Links.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        self: json["self"],
      );

  Map<String, dynamic> toJson() => {
        "self": self,
      };
}

class Matches {
  final List<int> title;
  final List<dynamic> snippet;

  Matches({
    required this.title,
    required this.snippet,
  });

  factory Matches.fromRawJson(String str) => Matches.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Matches.fromJson(Map<String, dynamic> json) => Matches(
        title: List<int>.from(json["title"].map((x) => x)),
        snippet: List<dynamic>.from(json["snippet"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "title": List<dynamic>.from(title.map((x) => x)),
        "snippet": List<dynamic>.from(snippet.map((x) => x)),
      };
}
