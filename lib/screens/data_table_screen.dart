import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:csv_read/database_function/hive_model.dart';
import 'package:csv_read/main.dart' as main;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_datagrid_export/export.dart';

import '../database_function/hive_function.dart';
import '../main.dart';
import 'package:csv_read/savefile.dart' as helper;
class DataTableClass extends StatefulWidget {
  final String sheetName;

  const DataTableClass(
      {super.key, required this.dataList, required this.sheetName});

  final List<main.InitialCompanyData> dataList;

  @override
  State<DataTableClass> createState() => _DataTableClassState();
}

class _DataTableClassState extends State<DataTableClass> {
  List<DirectorDataClass> data = [];

  @override
  void initState() {
    // TODO: implement initState

    List<String> urls = List<String>.from(widget.dataList.map((e) =>
    'https://api.company-information.service.gov.uk/company/${e.companyData !=
        null ? e.companyData!.items.isEmpty ? '' : e.companyData!.items[0]
        .companyNumber : ''}/officers'));
    hitApiRequestsInBatches(urls, 10).then((value) {
      // Process API responses
      final directorDataList = <DirectorDataClass>[];

      for (int i = 0; i < value.length; i++) {

        final directorInfo = value[i].isEmpty || value[i] == '' ||
            (jsonDecode(value[i]) as Map<String, dynamic>).containsKey('errors')
            ? null
            : DirectorDetailsModel.fromJson(jsonDecode(value[i]));

        final directorClass = DirectorDataClass(
            companyData: widget.dataList[i], directorDetails: directorInfo);
        directorDataList.add(directorClass);
      }

      // Update state with processed data
      setState(() {
        data = directorDataList;
      });

      // Print the length of data
      print(data.length.toString());
    });


    super.initState();
  }

  // void

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: dataLoading == false ? FloatingActionButton(
        onPressed: () async {
          final  workbook = _key.currentState!.exportToExcelWorkbook();
          final List<int> bytes = workbook.saveAsStream();
          // String dir = (await getApplicationDocumentsDirectory()).path;

          await helper.saveAndLaunchFile(bytes, 'DataGrid${helper.generateRandomString(5)}.xlsx');
        }, child: const Icon(Icons.save),) : const SizedBox(),
      body: dataLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SfDataGrid(
        key: _key,
        source: EmployeeDataSource(employees: data),
        columns: [
          GridColumn(
              columnName: 'company name',
              columnWidthMode: ColumnWidthMode.fitByColumnName,
              label: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerRight,
                  child: const Text(
                    'Company Name',
                    overflow: TextOverflow.ellipsis,
                  ))),
          GridColumn(
              columnName: 'company number',
              columnWidthMode: ColumnWidthMode.auto
              ,
              label: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Director Names',
                    overflow: TextOverflow.ellipsis,
                  ))),
          GridColumn(
              columnName: 'designation',
              columnWidthMode: ColumnWidthMode.auto,
              label: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Designation',
                    overflow: TextOverflow.ellipsis,
                  ))),
          GridColumn(
              columnName: 'salary',
              columnWidthMode: ColumnWidthMode.auto,
              label: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerRight,
                  child: const Text(
                    'Salary',
                    overflow: TextOverflow.ellipsis,
                  ))),
        ],
      ),
      /*SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowHeight: 80,
                  columns: const [
                    DataColumn(label: Text('Company Name')),
                    DataColumn(label: Text('Comapny Number')),
                    DataColumn(label: Text('Directors')),
                    DataColumn(label: Text('Directors Contacts')),
                    DataColumn(label: Text('D.O.B')),
                    DataColumn(label: Text('Resign Date')),
                    DataColumn(label: Text('Refresh')),
                  ],
                  rows: data
                      .map((e) => DataRow(cells: [
                            DataCell(
                              SizedBox(
                                  width: 100,
                                  child: Text(e.companyData.companyName)),
                            ),
                            DataCell(
                              Text(e.companyData.companyData != null
                                  ? e.companyData.companyData!.items.isNotEmpty
                                      ? e.companyData.companyData!.items[0]
                                          .companyNumber
                                      : ''
                                  : ''),
                            ),
                            DataCell(
                              SizedBox(
                                  width: 100,
                                  child: Text(e.directorDetails != null
                                      ? e.directorDetails!.items.isNotEmpty
                                          ? e.directorDetails!.items
                                              .map((e) => e.name)
                                              .toList()
                                              .join('\n')
                                          : ''
                                      : '')),
                            ),
                            DataCell(
                              SizedBox(
                                  width: 100,
                                  child: Text(e.directorDetails != null
                                      ? e.directorDetails!.items.isNotEmpty
                                          ? e.directorDetails!.items
                                              .map((e) => e.personNumber)
                                              .toList()
                                              .join('\n')
                                          : ''
                                      : '')),
                            ),
                            DataCell(
                              SizedBox(
                                  width: 100,
                                  child: Text(e.directorDetails != null
                                      ? e.directorDetails!.items.isNotEmpty
                                          ? e.directorDetails!.items
                                              .map((e) =>
                                                  '${e.dateOfBirth.month}/${e.dateOfBirth.year}')
                                              .toList()
                                              .join('\n')
                                          : ''
                                      : '')),
                            ),
                            DataCell(
                              SizedBox(
                                  width: 100,
                                  child: Text(e.directorDetails != null
                                      ? e.directorDetails!.items.isNotEmpty
                                          ? e.directorDetails!.items
                                              .map((e) =>
                                                  '${e.resignedOn}')
                                              .toList()
                                              .join('\n')
                                          : ''
                                      : '')),
                            ),
                            DataCell(
                              IconButton(
                                  onPressed: () async {
                                    if (e.companyData.companyData == null) {
                                      final response = await fixIndividualDataRow(
                                          url:
                                              'https://api.company-information.service.gov.uk/search?q=${e.companyData.companyName}&items_per_page=1&start_index=1');
                                      final decodedData =
                                          main.ComapnyDetailsModelModel
                                              .fromJson(jsonDecode(response));

                                      final data1 = main.InitialCompanyData(
                                          companyName:
                                              e.companyData.companyName,
                                          companyData: decodedData);

                                      final data2 = DirectorDataClass(
                                          companyData: data1,
                                          directorDetails: e.directorDetails);
                                      int indexOf = data.indexWhere((element) =>
                                          element.companyData.companyName ==
                                          e.companyData.companyName);

                                      data.replaceRange(
                                          indexOf, indexOf, [data2]);
                                      data.toSet().toList();

                                      setState(() {});
                                    }
                                    if(e.directorDetails == null){
                                      final response1 = await fixIndividualDataRow(
                                          url: 'https://api.company-information.service.gov.uk/company/${e.companyData.companyData != null ? e.companyData.companyData!.items.isEmpty ? '' : e.companyData.companyData!.items[0].companyNumber : ''}/officers');
                                      final data1 = main.InitialCompanyData(
                                          companyName:
                                          e.companyData.companyName,
                                          companyData: e.companyData.companyData);

                                      final data2 = DirectorDataClass(
                                          companyData: data1,
                                          directorDetails: DirectorDetailsModel.fromJson(jsonDecode(response1)));
                                      int indexOf = data.indexWhere((element) =>
                                      element.companyData.companyName ==
                                          e.companyData.companyName);
                                      data.replaceRange(
                                          indexOf, indexOf, [data2]);
                                      data.toSet().toList();

                                    }

                                  },
                                  icon: const Icon(Icons.refresh)),
                            ),
                          ]))
                      .toList(),
                ),
              ),
            ),*/
      appBar: AppBar(
        title: const Text('Table Screen'),
      ),
    );
  }

  bool dataLoading = false;
  List<String> multipleResponses = [];

  Future<String> fixIndividualDataRow({required String url}) async {
    log(url);
    log(url);
    final response = await retry(
      // Make a GET request
          () =>
          http.get(Uri.parse(url), headers: {
            "Authorization": 'Basic ${base64Encode(
                utf8.encode('${main.apiKey}:'))}'
          }).timeout(const Duration(seconds: 30)),

      onRetry: (reason) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Retrying. Error Occurred\n${reason.toString()}')));
      },
      // Retry on SocketException or TimeoutException
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
    return response.body;
  }

  final databaseHelper = DatabaseHelper();

/*  Future<List<String>> hitApiRequestsInBatches(
      List<String> urls, int batchSize) async {
    final stopwatch = Stopwatch()..start();
    setState(() => dataLoading = true);
    final responses = <String>[];
    final _apiKey = base64Encode(utf8.encode('$apiKey:'));

    int urlIndex = 0;

    while (urlIndex < urls.length) {
      int urlsWithoutResponseCount = 0;

      for (final companyData in widget.dataList) {
        final companyName = companyData.companyName;

        try {
          final cachedData = await databaseHelper.getCompany(widget.sheetName, companyName);

          if (cachedData != null && cachedData.directorDetails != null) {
            log('Response from database for $companyName');
            responses.add(cachedData.directorDetails!);
          } else {
            final url = urls[urlIndex];

            print(url);
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

            if (response.statusCode == 429) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                  'Too Many Requests on Current API key. Please wait for 5 minutes at least.\nSelect your file again after some time.',
                ),
              ));
              await Future.delayed(const Duration(minutes: 5, seconds: 10));
            } else {
              log('API Response for $companyName: ${response.body}');
              final company = Company(
                companyName: companyName,
                companyDetails: jsonEncode(companyData.companyData?.toJson()),
                directorDetails: response.body,
              );
              await databaseHelper.updateCompany(widget.sheetName, company);
              responses.add(response.body);
            }
            urlsWithoutResponseCount++;
          }
        } catch (e) {
          print(e.toString());
          urlsWithoutResponseCount++;
        }
      }

      urlIndex++;

      if (urlsWithoutResponseCount == widget.dataList.length && urls.length % 600 == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'API limit exceeded. Pausing for 5 minutes and 10 seconds.',
          ),
        ));
        await Future.delayed(const Duration(minutes: 5, seconds: 10));
      }
    }

    setState(() => dataLoading = false);
    stopwatch.stop();
    log('Time taken for ${urls.length} APIs: ${stopwatch.elapsed.inMinutes.toString()} minutes');
    return responses;
  }*/

  Future<List<String>> hitApiRequestsInBatches(
      List<String> urls, int batchSize) async {
    final stopwatch = Stopwatch()..start();

    setState(() => dataLoading = true);

    final responses = <String>[];
    final _apiKey = base64Encode(utf8.encode('$apiKey:'));

    bool pauseApiRequest = false;

    for (int i = 0; i < urls.length; i += batchSize) {
      final batchUrls = urls.sublist(
        i,
        i + batchSize < urls.length ? i + batchSize : urls.length,
      );

      if (pauseApiRequest) {
        await Future.delayed(const Duration(seconds: 2, minutes: 5));
        pauseApiRequest = false;
      } else {
        for (String url in batchUrls) {
          final companyName = widget.dataList[i].companyName;

          try {
            /*  final cachedData = await databaseHelper.getCompany(widget.sheetName, companyName);

            if (cachedData != null && cachedData.directorDetails != null) {
              log('Response from database');
              responses.add(cachedData.directorDetails!);
            }
            else {
              final response = await retry(
                    () => http.get(Uri.parse(url), headers: {'Authorization': 'Basic $_apiKey'}),
                onRetry: (reason) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Retrying. Error Occurred\n$reason'),
                  ),
                ),
                retryIf: (error) => error is SocketException || error is TimeoutException,
              );

              if (response.statusCode == 502) {
                responses.add('');
              } else if (response.statusCode == 429) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                    'Too Many Requests on Current API key. Please wait for 5 minutes at least.\nSelect your file again after some time.',
                  ),
                ));
                pauseApiRequest = true;
              } else {
                final company = Company(
                  companyName: companyName,
                  companyDetails: jsonEncode(widget.dataList.firstWhere((element) => element.companyName == companyName).companyData!.toJson()),
                  directorDetails: response.body,
                );
                await databaseHelper.updateCompany(widget.sheetName, company);
                responses.add(response.body);
              }
            }*/
            {
              final response = await retry(
                    () => http.get(Uri.parse(url), headers: {'Authorization': 'Basic $_apiKey'}),
                onRetry: (reason) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Retrying. Error Occurred\n$reason'),
                  ),
                ),
                retryIf: (error) => error is SocketException || error is TimeoutException,
              );

              if (response.statusCode == 502) {
                responses.add('');
              } else if (response.statusCode == 429) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                    'Too Many Requests on Current API key. Please wait for 5 minutes at least.\nSelect your file again after some time.',
                  ),
                ));
                pauseApiRequest = true;
              } else {
                final company = Company(
                  companyName: companyName,
                  companyDetails: jsonEncode(widget.dataList.firstWhere((element) => element.companyName == companyName).companyData!.toJson()),
                  directorDetails: response.body,
                );
                await databaseHelper.updateCompany(widget.sheetName, company);
                responses.add(response.body);
              }
            }
          } catch (error) {
            final company2 = Company(
              companyName: companyName,
              companyDetails: jsonEncode(widget.dataList.firstWhere((element) => element.companyName == companyName).companyData!.toJson()),
              directorDetails: '',
            );
            await databaseHelper.updateCompany(widget.sheetName, company2);
            responses.add('');
            print('Error fetching data for $url: $error');
            // Consider logging specific error details
          }
        }
      }
    }

    setState(() => dataLoading = false);
    stopwatch.stop();
    log('Time taken for ${urls.length} APIs: ${stopwatch.elapsed.inMinutes.toString()} minutes');

    return responses;
  }



  final GlobalKey<SfDataGridState> _key = GlobalKey<SfDataGridState>();
}

class DirectorDataClass {
  final DirectorDetailsModel? directorDetails;
  final main.InitialCompanyData companyData;

  DirectorDataClass({this.directorDetails, required this.companyData});
}

class DirectorDetailsModel {
  final int activeCount;
  final String etag;
  final List<Item2> items;
  final int itemsPerPage;
  final String kind;
  final DirectorDetailsModelLinks links;
  final int resignedCount;
  final int inactiveCount;
  final int startIndex;
  final int totalResults;

  DirectorDetailsModel({
    required this.activeCount,
    required this.etag,
    required this.items,
    required this.itemsPerPage,
    required this.kind,
    required this.links,
    required this.resignedCount,
    required this.inactiveCount,
    required this.startIndex,
    required this.totalResults,
  });

  factory DirectorDetailsModel.fromRawJson(String str) =>
      DirectorDetailsModel.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  factory DirectorDetailsModel.fromJson(Map<String, dynamic> json) {
    return DirectorDetailsModel(
      activeCount: json["active_count"] ?? 0,
      etag: json["etag"] ?? "",
      items: ((json["items"] ?? []) as List<dynamic>)
          .map((x) => Item2.fromJson(x as Map<String, dynamic>))
          .toList(),
      itemsPerPage: json["items_per_page"] ?? 0,
      kind: json["kind"] ?? "",
      links: DirectorDetailsModelLinks.fromJson(json["links"] ?? {}),
      resignedCount: json["resigned_count"] ?? 0,
      inactiveCount: json["inactive_count"] ?? 0,
      startIndex: json["start_index"] ?? 0,
      totalResults: json["total_results"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() =>
      {
        "active_count": activeCount,
        "etag": etag,
        "items": items.map((x) => x.toJson()).toList(),
        "items_per_page": itemsPerPage,
        "kind": kind,
        "links": links.toJson(),
        "resigned_count": resignedCount,
        "inactive_count": inactiveCount,
        "start_index": startIndex,
        "total_results": totalResults,
      };
}

class Address {
  final String addressLine1;
  final String addressLine2;
  final String country;
  final String locality;
  final String postalCode;
  final String premises;
  final String region;

  Address({
    required this.addressLine1,
    required this.addressLine2,
    required this.country,
    required this.locality,
    required this.postalCode,
    required this.premises,
    required this.region,
  });

  factory Address.fromRawJson(String str) =>
      Address.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressLine1: json["address_line_1"] ?? "",
      addressLine2: json["address_line_2"] ?? "",
      country: json["country"] ?? "",
      locality: json["locality"] ?? "",
      postalCode: json["postal_code"] ?? "",
      premises: json["premises"] ?? "",
      region: json["region"] ?? "",
    );
  }

  Map<String, dynamic> toJson() =>
      {
        "address_line_1": addressLine1,
        "address_line_2": addressLine2,
        "country": country,
        "locality": locality,
        "postal_code": postalCode,
        "premises": premises,
        "region": region,
      };
}

class Item2 {
  final Address address;
  final String appointedOn;
  final bool isPre1992Appointment;
  final String countryOfResidence;
  final DateOfBirth dateOfBirth;
  final ItemLinks links;
  final String name;
  final String nationality;
  final String occupation;
  final String officerRole;
  final String personNumber;
  final String resignedOn;

  Item2({
    required this.address,
    required this.appointedOn,
    required this.isPre1992Appointment,
    required this.countryOfResidence,
    required this.dateOfBirth,
    required this.links,
    required this.name,
    required this.nationality,
    required this.occupation,
    required this.officerRole,
    required this.personNumber,
    required this.resignedOn,
  });

  factory Item2.fromRawJson(String str) => Item2.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Item2.fromJson(Map<String, dynamic> json) =>
      Item2(
        address: Address.fromJson(json["address"] ?? {}),
        appointedOn: json["appointed_on"] ?? "",
        isPre1992Appointment: json["is_pre_1992_appointment"] ?? false,
        countryOfResidence: json["country_of_residence"] ?? "",
        dateOfBirth: DateOfBirth.fromJson(json["date_of_birth"] ?? {}),
        links: ItemLinks.fromJson(json["links"] ?? {}),
        name: json["name"] ?? "",
        nationality: json["nationality"] ?? "",
        occupation: json["occupation"] ?? "",
        officerRole: json["officer_role"] ?? "",
        personNumber: json["person_number"] ?? "",
        resignedOn: json["resigned_on"] ?? "",
      );

  Map<String, dynamic> toJson() =>
      {
        "address": address.toJson(),
        "appointed_on": appointedOn,
        "is_pre_1992_appointment": isPre1992Appointment,
        "country_of_residence": countryOfResidence,
        "date_of_birth": dateOfBirth.toJson(),
        "links": links.toJson(),
        "name": name,
        "nationality": nationality,
        "occupation": occupation,
        "officer_role": officerRole,
        "person_number": personNumber,
        "resigned_on": resignedOn,
      };
}

class DateOfBirth {
  final int month;
  final int year;

  DateOfBirth({
    required this.month,
    required this.year,
  });

  factory DateOfBirth.fromRawJson(String str) =>
      DateOfBirth.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  factory DateOfBirth.fromJson(Map<String, dynamic> json) {
    return DateOfBirth(
      month: json["month"] ?? 0,
      year: json["year"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() =>
      {
        "month": month,
        "year": year,
      };
}

class ItemLinks {
  final String self;
  final Officer officer;

  ItemLinks({
    required this.self,
    required this.officer,
  });

  factory ItemLinks.fromRawJson(String str) =>
      ItemLinks.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  factory ItemLinks.fromJson(Map<String, dynamic> json) {
    return ItemLinks(
      self: json["self"] ?? "",
      officer: Officer.fromJson(json["officer"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() =>
      {
        "self": self,
        "officer": officer.toJson(),
      };
}

class Officer {
  final String appointments;

  Officer({
    required this.appointments,
  });

  factory Officer.fromRawJson(String str) => Officer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Officer.fromJson(Map<String, dynamic> json) =>
      Officer(
        appointments: json["appointments"] ?? "Default Appointment",
      );

  Map<String, dynamic> toJson() =>
      {
        "appointments": appointments,
      };
}

class DirectorDetailsModelLinks {
  final String self;

  DirectorDetailsModelLinks({
    required this.self,
  });

  factory DirectorDetailsModelLinks.fromRawJson(String str) =>
      DirectorDetailsModelLinks.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DirectorDetailsModelLinks.fromJson(Map<String, dynamic> json) =>
      DirectorDetailsModelLinks(
        self: json["self"] ?? "Default Self",
      );

  Map<String, dynamic> toJson() =>
      {
        "self": self,
      };
}

class Person {
  final String firstName;
  final String lastName;
  int age;

  Person({required this.firstName, required this.lastName, required this.age});
}

class EmployeeDataSource extends DataGridSource {
  EmployeeDataSource({required List<DirectorDataClass> employees}) {
    dataGridRows = employees
        .map<DataGridRow>((dataGridRow) =>
        DataGridRow(cells: [
        DataGridCell<String>(columnName: 'company name',
            value: dataGridRow.companyData.companyName),
        DataGridCell<String>(columnName: 'company number',
            value: dataGridRow.companyData.companyData != null
                ? dataGridRow.companyData.companyData!.items.isNotEmpty
                ? dataGridRow.companyData.companyData!.items[0]
                .companyNumber
                : ''
                : ''),
        DataGridCell<String>(
            columnName: 'designation',
            value: dataGridRow.directorDetails != null
                ? dataGridRow.directorDetails!.items.isNotEmpty
                ? dataGridRow.directorDetails!.items
                .map((e) => e.name)
                .toList()
                .join('\n')
                : ''
                : ''),
     DataGridCell<String>(
    columnName: 'salary', value:dataGridRow.directorDetails != null
         ? dataGridRow.directorDetails!.items.isNotEmpty
         ? dataGridRow.directorDetails!.items
         .map((e) => e.personNumber)
         .toList()
         .join('\n')
         : ''
         : ''),
    ])
    )
    .
    toList
    (
    );
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
          return Container(
              alignment: (dataGridCell.columnName == 'id' ||
                  dataGridCell.columnName == 'salary')
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                dataGridCell.value.toString(),
                overflow: TextOverflow.ellipsis,
              ));
        }).toList());
  }
}