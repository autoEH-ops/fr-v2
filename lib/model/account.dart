class Account {
// -- Create Accounts table
// CREATE TABLE Accounts (
//     id SERIAL PRIMARY KEY,
//     name TEXT NOT NULL,
//     phone TEXT NOT NULL,
//     email TEXT UNIQUE NOT NULL,
//     role TEXT NOT NULL,
//     image_url TEXT NULL,
//     created_at TIMESTAMPTZ DEFAULT NOW()
// );
  int? id;
  String name;
  String phone;
  String email;
  String role;
  String? imageUrl;
  DateTime? createdAt;

  Account(this.id, this.name, this.phone, this.email, this.role, this.createdAt,
      this.imageUrl);
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      map['id'] as int?,
      map['name'] as String,
      map['phone'] as String,
      map['email'] as String,
      map['role'] as String,
      map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      map['image_url'] as String?,
    );
  }
}
