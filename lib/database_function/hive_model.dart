class Company {
  final String companyName;
   String companyDetails;
  final String? directorDetails;

  Company({
    required this.companyName,
    required this.companyDetails,
    this.directorDetails,
  });

  // Factory constructor to create a Company object from a Map (used for database queries)
  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      companyName: map['companyName'] as String,
      companyDetails: map['companyDetails'] as String,
      directorDetails: map['directorDetails'] as String?,
    );
  }

  // Method to convert the Company object to a Map (used for database insertions)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'companyName': companyName,
      'companyDetails': companyDetails,
      'directorDetails': directorDetails,
    };
  }
}
