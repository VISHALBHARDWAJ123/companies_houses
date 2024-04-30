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
  String sheetName = '';

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

                    setState(() {
                      sheetName = excel.sheets.keys.toList()[0];
                    });

                    print(excel.sheets[sheetName]!.maxRows);
                    final element = excel.sheets[sheetName]!;
                    csvList.clear();
                    for (var data in element.selectRange(
                        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
                        end: CellIndex.indexByColumnRow(
                            columnIndex: 1,
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
                      csvList.removeWhere(
                          (element) => element.toLowerCase().contains('false'));
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
                          if (csvList[i].toLowerCase() != 'false') {
                            String companyName = csvList[i];
                            ComapnyDetailsModelModel? model =
                                multipleResponses[i].isEmpty || jsonDecode(multipleResponses[i]) is! Map<String, dynamic>
                                    ? null
                                    : ComapnyDetailsModelModel.fromJson(
                                        jsonDecode(
                                          multipleResponses[i],
                                        ),
                                      );

                            setState(() {
                              companyData.add(InitialCompanyData(
                                  companyName: companyName,
                                  companyData: model));
                            });
                          }
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataTableClass(
                              dataList: companyData,
                              sheetName: sheetName,
                            ),
                          ),
                        );
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
                    ),   multipleResponses.isEmpty
                  ? const SizedBox()
                  : GestureDetector(
                      onTap: ()async{await DatabaseHelper().deleteTableData(tableName: sheetName); },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 50),
                          child: Text(
                            'Clear List',
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

  @override
  void dispose() {
    super.dispose();
    Hive.close();
  }

  List<InitialCompanyData> companyData = [];
  bool dataLoading = false;
  final dio = Dio();

  void printBoxStructure(Box box) {
    print('Box: ${box.name}');
    print('Keys:');
    for (var key in box.keys) {
      print(key);
    }
    print('Values:');
    for (var value in box.values) {
      print(value);
    }
  }
  final databaseHelper = DatabaseHelper();

/*  Future<List<String>> hitApiRequestsInBatches(
      List<String> urls, int batchSize) async {
    // Start stopwatch to measure execution time
    final stopwatch = Stopwatch()..start();

    // Set dataLoading state to true to indicate data loading is in progress
    setState(() => dataLoading = true);

    // List to store API responses
    final responses = <String>[];

    // Encode API key for authorization header
    final _apiKey = base64Encode(utf8.encode('$apiKey:'));

    // Iterate over URLs in batches
    for (int i = 0; i < urls.length; i += batchSize) {
      // Get the current batch of URLs
      final batchUrls = urls.sublist(
        i,
        i + batchSize < urls.length ? i + batchSize : urls.length,
      );

      // Counter to track the number of URLs without responses in the database
      int urlsWithoutResponseCount = 0;

      // Check each URL in the batch for response in the database or make API request
      for (var url in batchUrls) {
        final companyName = url.split('?q=')[1].split('&')[0];
        try {
          // Check if response for the URL is cached in the database
          final cachedData = await databaseHelper.getCompany(sheetName, companyName);

          // If response is cached, add it to responses list
          if (cachedData != null && cachedData.companyDetails != null) {
            log('Response from database for $companyName');
            responses.add(cachedData.companyDetails);
          } else {
            // Increment count if response is not cached


            // Make API request for URLs with no response in database
            final response = await retry(
                  () => http.get(Uri.parse(url),
                  headers: {'Authorization': 'Basic $_apiKey'}),
              onRetry: (reason) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Retrying. Error Occurred\n$reason'),
                ),
              ),
              retryIf: (error) =>
              error is SocketException || error is TimeoutException,
            );

            // Handle API rate limit exceeded error
            if (response.statusCode == 429) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                  'Too Many Requests on Current API key. Please wait for 5 minutes at least.\nSelect your file again after some time.',
                ),
              ));
              // Pause for 5 minutes and 10 seconds if API limit is reached
              await Future.delayed(const Duration(minutes: 5, seconds: 10));
            } else {
              log('API Response for $companyName: ${response.body}');
              final company = Company(
                companyName: companyName,
                companyDetails: response.body,
                directorDetails: null,
              );
              await databaseHelper.insertCompany(sheetName, company);
              responses.add(response.body);
            }
            urlsWithoutResponseCount++;
          }
        } catch (e) {
          print(e.toString());
          // Increment count if an error occurs while fetching from database
          urlsWithoutResponseCount++;
        }
      }

      // If all URLs in the batch have no responses and total URLs is > 599, pause for API limit
      if (urlsWithoutResponseCount == batchUrls.length && urls.length %600 == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'API limit exceeded. Pausing for 5 minutes and 10 seconds.',
          ),
        ));
        await Future.delayed(const Duration(minutes: 5, seconds: 10));
      }

      // If all URLs in the batch have responses in database, continue to next batch
      if (urlsWithoutResponseCount == 0) {
        continue;
      }
    }

    // Set dataLoading state to false to indicate data loading is complete
    setState(() => dataLoading = false);

    // Stop stopwatch and log total execution time
    stopwatch.stop();
    log('Time taken for ${urls.length} APIs: ${stopwatch.elapsed.inMinutes.toString()} minutes');

    // Return list of API responses
    return responses;
  }*/





  Future<List<String>> hitApiRequestsInBatches(
      List<String> urls, int batchSize) async {
    final stopwatch = Stopwatch()..start();

    // Open Hive box with error handling


    setState(() => dataLoading = true);

    final responses = <String>[];
    final _apiKey = base64Encode(
        utf8.encode('$apiKey:'));
    bool  pauseApiRequest = false;// Pre-compute base64 for efficiency

    for (int i = 0; i < urls.length; i += batchSize) {
      final batchUrls = urls.sublist(
          i, i + batchSize < urls.length ? i + batchSize : urls.length);



      if(pauseApiRequest == true) {
        await Future.delayed(const Duration(seconds: 2, minutes: 5));
        pauseApiRequest = false;
      }else{
        final batchFutures = batchUrls.map((url) async {
          try {
            final companyName = url.split('?q=')[1].split('&')[0];
            try {
              final cachedData = await databaseHelper.getCompany(sheetName, companyName);

              if (cachedData != null && cachedData.companyDetails != null) {
                log('Response from database');
                return cachedData.companyDetails; // Use cached data if available
              } else {
                log('Data is not available ');
              }
            } catch (e) {
              print(e.toString());
            }
            final response = await retry(
                  () => http.get(Uri.parse(url),
                  headers: {'Authorization': 'Basic $_apiKey'}),
              onRetry: (reason) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Retrying. Error Occurred\n$reason'),
                ),
              ),
              retryIf: (error) =>
              error is SocketException || error is TimeoutException,
            );
            if(response.statusCode == 502){
              return '';
            }

            if (response.statusCode == 429) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                  'Too Many Requests on Current API key. Please wait for 5 minutes at least.\nSelect your file again after some time.',
                ),
              ));
              pauseApiRequest = true;

              // Consider implementing exponential backoff here
            } else {
              final company = Company(
                  companyName: companyName, companyDetails: response.body);
              await databaseHelper
                  .insertCompany(sheetName,company,);
            }

            return response.body;
          } catch (error) {
            final company = Company(
                companyName: url.split('?q=')[1].split('&')[0],
                companyDetails: '');
            await databaseHelper
                .insertCompany(sheetName,company,);
            print('Error fetching data for $url: $error');
            // Consider logging specific error details
            return ''; // Or handle the error differently
          }
        }).toList();

        final batchResponses = await Future.wait(batchFutures);
        responses.addAll(batchResponses);
        log('Total Responses ${responses.length}');
      }

    }

    setState(() => dataLoading = false);
    stopwatch.stop();
    log('Time taken for ${urls.length} APIs: ${stopwatch.elapsed.inMinutes.toString()} minutes');

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
        pageNumber: json["page_number"]??0,
        itemsPerPage: json["items_per_page"]??0,
        kind: json["kind"]??'',
        startIndex: json["start_index"]??0,
        items: json["items"] == null || json["items"].isEmpty
            ? []
            : List<Item2>.from(json["items"].map((x) => Item2.fromJson(x))),
        totalResults: json["total_results"]??0,
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
        companyNumber: json["company_number"] ?? '',
        description: json["description"] ?? '',
        addressSnippet: json["address_snippet"] ?? '',
        companyStatus: json["company_status"] ?? '',
        snippet: json["snippet"] ?? '',
        kind: json["kind"] ?? '',
        dateOfCreation: json["date_of_creation"] ?? '',
        // descriptionIdentifier:
        // json["description_identifier"]==null?[]:List<String>.from((json["description_identifier"] == null?[]:json["description_identifier"]).map((x) => x)),
        address: Address.fromJson(json["address"] ??
            {
              "address": {
                "postal_code": "",
                "locality": "",
                "premises": "",
                "country": "",
                "address_line_1": ""
              }
            }),
        companyType: json["company_type"] ?? '',
        title: json["title"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "company_number": companyNumber,
        "description": description,
        "address_snippet": addressSnippet,
        "company_status": companyStatus,
        "snippet": snippet,
        "kind": kind,
        "date_of_creation": "${dateOfCreation}",
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
        postalCode: json["postal_code"] ?? '',
        locality: json["locality"] ?? '',
        premises: json["premises"] ?? '',
        country: json["country"] ?? '',
        addressLine1: json["address_line_1"] ?? '',
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
