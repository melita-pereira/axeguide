import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient supabase = Supabase.instance.client;
Future<List<Map<String, dynamic>>> fetchLocations() async {
  final response = await supabase.from('locations').select().order('name');
  return List<Map<String, dynamic>>.from(response);
}
