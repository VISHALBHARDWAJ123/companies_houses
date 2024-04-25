import 'dart:io';

import 'package:csv_read/database_function/hive_model.dart';
import 'package:hive/hive.dart';

class HiveService {
  static const String boxName = 'companiesDetails';

  Future<void> initDatabase() async {
    var path = Directory.systemTemp.path;
    Hive
      ..init(path)
      ..registerAdapter(CompanyAdapter());
  }

  // Add company to Hive
  Future<void> addCompany(Company company) async {
    final box = await Hive.openBox(boxName);
    await box.put(company.companyName, company);
  }
}
