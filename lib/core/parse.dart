/// Postgres numeric columns can arrive as num or String. Normalize them.
num? toNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}