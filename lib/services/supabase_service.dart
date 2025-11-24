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

  Future<List<Map<String, dynamic>>> fetchLocationsByFilters({
    String? areaTag,
    List<String>? categoryNames,
    int? parentId,
  }) async {
    var query = client
        .from('locations')
        .select('id, name, area_tag, description, latitude, longitude, town, hours, map_link, image_url, parent_id, temporary_parent_id');

    // Apply area_tag filter
    if (areaTag != null) {
      query = query.ilike('area_tag', '%$areaTag%');
    }

    // Apply parent_id filter
    if (parentId != null) {
      query = query.eq('parent_id', parentId);
    }

    var response = await query.order('name');
    var results = List<Map<String, dynamic>>.from(response);

    // If no category filter, return all results
    if (categoryNames == null || categoryNames.isEmpty) {
      return results;
    }

    // Batch fetch category IDs and location mappings in parallel
    final categoryFuture = client
        .from('categories')
        .select('id')
        .inFilter('name', categoryNames);

    final categoryResponse = await categoryFuture;
    
    if (categoryResponse.isEmpty) {
      return results;
    }

    final categoryIds = categoryResponse
        .map((item) => item['id'] as int)
        .toList();

    // Fetch all location IDs that have these categories in one query
    final locationCategoriesResponse = await client
        .from('location_categories')
        .select('location_id')
        .inFilter('category_id', categoryIds);

    final locationIds = locationCategoriesResponse
        .map((item) => item['location_id'] as int)
        .toSet();

    // Filter results to only include locations with matching categories
    return results.where((loc) => locationIds.contains(loc['id'])).toList();
  }
}
