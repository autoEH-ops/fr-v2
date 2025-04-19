class Otp {
  int accountId;
  String otp;

  Otp(this.accountId, this.otp);
  factory Otp.fromMap(Map<String, dynamic> map) {
    return Otp(
      map['account_id'] as int,
      map['otp'] as String,
    );
  }
}
