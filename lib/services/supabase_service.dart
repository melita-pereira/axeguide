import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchLocationsByTags(List<String> filters) async {
    if (filters.isEmpty) {
      return [];
    }
    final orClause = filters.map((f) => "area_tag.ilike.%$f%").join(',');
    final res = await client
        .from('locations')
        .select('id, name, area_tag, description, latitude, longitude, town, hours, map_link, image_url, parent_id, temporary_parent_id')
        .or(orClause)
        .order('name');

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchInstagramAccounts({String? areaTag}) async {
    final q = client.from('instagram_accounts').select('id, handles, account_name');

    final res = areaTag == null
        ? await q.order('account_name')
        : await q.ilike('area_tag', '%$areaTag%').order('account_name');
    return List<Map<String, dynamic>>.from(res);
  }
}
