class Setting {
// -- Create system_settings table
// CREATE TABLE system_settings (
//     id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
//     setting TEXT NOT NULL,
//     value TEXT NOT NULL,
//     created_at TIMESTAMPTZ DEFAULT NOW(),
//     last_updated TIMESTAMPTZ,
//     updated_by TEXT
// );
  String? id;
  String setting;
  String value;
  DateTime? createdAt;
  DateTime? lastUpdated;
  int? updatedBy;
  Setting(this.id, this.setting, this.value, this.createdAt, this.lastUpdated,
      this.updatedBy);

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      map['id'] as String?,
      map['setting'] as String,
      map['value'] as String,
      map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
      map['updated_by'] as int?,
    );
  }
}
