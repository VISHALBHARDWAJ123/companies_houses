import 'package:hive/hive.dart';

part 'hive_model.g.dart';


@HiveType(typeId: 0)
class Company {
  @HiveField(0)
  late String companyName; // Primary key

  @HiveField(1)
  late String companyDetails;



  // Constructor
  Company({
    required this.companyName,
    required this.companyDetails,

  });
}
