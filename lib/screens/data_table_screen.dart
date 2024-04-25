import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:csv_read/main.dart' as main;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

class DataTableClass extends StatefulWidget {
  const DataTableClass({super.key, required this.dataList});

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
    'https://api.company-information.service.gov.uk/company/${e.companyData!= null ? e.companyData!.items.isEmpty ? '' : e.companyData!.items[0].companyNumber : ''}/officers'));

    hitApiRequestsInBatches(urls, 10).whenComplete(() {
      print(jsonEncode(multipleResponses));

      for (int i = 0; i < multipleResponses.length; i++) {
        final directorInfo = multipleResponses[i].isEmpty
            ? null
            : DirectorDetailsModel.fromJson(jsonDecode(multipleResponses[i]));

        final directorClass = DirectorDataClass(
            companyData: widget.dataList[i], directorDetails: directorInfo);
        data.add(directorClass);
      }
      print(data.length.toString());
    });
    super.initState();
  }



  // void

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: dataLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowHeight: 80,
                  columns: const [
                    DataColumn(label: Text('Company Name')),
                    DataColumn(label: Text('Comapny Number')),
                    DataColumn(label: Text('Directors')),
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
                                  child: Text(e.directorDetails!=null?e.directorDetails!.items.isNotEmpty?e.directorDetails!.items[0].name:'':'')),
                            ),
                            DataCell(
                              IconButton(
                                  onPressed: () async {
                                    if (e.companyData.companyData == null) {
                                      final response = await fixIndividualDataRow(
                                          url:
                                              'https://api.company-information.service.gov.uk/search?q=${e.companyData.companyName}&items_per_page=1&start_index=1');
                                      final decodedData =
                                      main.ComapnyDetailsModelModel.fromJson(
                                              jsonDecode(response));

                                      final data1 = main.InitialCompanyData(
                                          companyName:
                                              e.companyData.companyName,companyData: decodedData);
String directorDetails = '';
                                      final response1 = await fixIndividualDataRow(url:  'https://api.company-information.service.gov.uk/company/${e.companyData.companyData != null ? e.companyData.companyData!.items.isEmpty ? '' : e.companyData.companyData!.items[0].companyNumber : ''}/officers');
                                      final data2 = DirectorDataClass(companyData: data1, directorDetails: e.directorDetails);
                                      int indexOf = data.indexWhere((element) => element.companyData.companyName == e.companyData.companyName);

                                      data.replaceRange(indexOf, indexOf, [data2]);
                                      data.toSet().toList();
                                      data.remove(e);
                                      setState(() {

                                      });
                                    }
                                    if(e.directorDetails == null){


                                    }
                                  },
                                  icon: const Icon(Icons.refresh)),
                            ),
                          ]))
                      .toList(),
                ),
              ),
            ),
      appBar: AppBar(
        title: const Text('Table Screen'),
      ),
    );
  }

  int _currentPage = 1;
  int _itemsPerPage = 10;
  bool dataLoading = false;
  List<String> multipleResponses = [];

  Future<String> fixIndividualDataRow({required String url}) async {
    log(url);
    log(url);
    final response = await retry(
      // Make a GET request
      () => http.get(Uri.parse(url), headers: {
        "Authorization": 'Basic ${base64Encode(utf8.encode('${main.apiKey}:'))}'
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

  Future<void> hitApiRequestsInBatches(
    List<String> urls,
    int batchSize,
  ) async {
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    setState(() {
      dataLoading = true;
    });
    List<String> responses = [];
    print('Basic ${base64Encode(utf8.encode('${main.apiKey}:'))}');

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
              "Authorization": 'Basic ${base64Encode(utf8.encode('${main.apiKey}:'))}'
            }).timeout(const Duration(seconds: 30)),

            onRetry: (reason) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Retrying. Error Occurred\n${reason.toString()}')));
            },
            // Retry on SocketException or TimeoutException
            retryIf: (e) => e is SocketException || e is TimeoutException,
          );
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
      await Future.delayed(const Duration(seconds: 2));

      // Add the responses from the current batch to the list of all responses
      responses.addAll(batchResponses);
      print('Total responses received: ${responses.length}');
    }
    setState(() {
      multipleResponses = responses;
      dataLoading = false;
    });
    stopwatch.stop();
    log("Time taken by All the ${urls.length} APIs ${stopwatch.elapsed.inMinutes}");
  }
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

  Map<String, dynamic> toJson() => {
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

  Map<String, dynamic> toJson() => {
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

  factory Item2.fromJson(Map<String, dynamic> json) => Item2(
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

  Map<String, dynamic> toJson() => {
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

  Map<String, dynamic> toJson() => {
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

  Map<String, dynamic> toJson() => {
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

  factory Officer.fromJson(Map<String, dynamic> json) => Officer(
        appointments: json["appointments"] ?? "Default Appointment",
      );

  Map<String, dynamic> toJson() => {
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

  Map<String, dynamic> toJson() => {
        "self": self,
      };
}

class Person {
  final String firstName;
  final String lastName;
  int age;

  Person({required this.firstName, required this.lastName, required this.age});
}
