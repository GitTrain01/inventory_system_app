import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://xczrwyoyozwhbkvpqwzn.supabase.co';
const supabaseAnonKey = 'sb_publishable_PMuvKaK9k3cVGaAy3uMEbA_QH2W_q2Y';

Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
}

/// Global client. Import this anywhere you talk to Supabase:
/// `supabase.from('products').select()`, `supabase.auth...`, etc.
final supabase = Supabase.instance.client;