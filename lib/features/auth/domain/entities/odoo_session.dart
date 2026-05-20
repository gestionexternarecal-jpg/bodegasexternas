class OdooSession {
  const OdooSession({
    required this.baseUrl,
    required this.database,
    required this.login,
    required this.uid,
    this.displayName,
  });

  final String baseUrl;
  final String database;
  final String login;
  final int uid;
  final String? displayName;

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'database': database,
        'login': login,
        'uid': uid,
        'displayName': displayName,
      };

  factory OdooSession.fromJson(Map<String, dynamic> json) {
    return OdooSession(
      baseUrl: json['baseUrl'] as String,
      database: json['database'] as String,
      login: json['login'] as String,
      uid: json['uid'] as int,
      displayName: json['displayName'] as String?,
    );
  }
}
