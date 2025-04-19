class Embedding {
// -- Create embeddings table
// CREATE TABLE embeddings (
//     id SERIAL PRIMARY KEY,
//     account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
//     embedding TEXT NOT NULL,
//     created_at TIMESTAMPTZ DEFAULT NOW()
// );

  int? id;
  int accountId;
  String embedding;
  DateTime? createdAt;

  Embedding(this.id, this.accountId, this.embedding, this.createdAt);
  factory Embedding.fromMap(Map<String, dynamic> map) {
    return Embedding(
      map['id'] as int?,
      map['account_id'] as int,
      map['embedding'] as String,
      map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
