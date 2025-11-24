import 'package:flutter_test/flutter_test.dart';
import 'package:axeguide/services/supabase_service.dart';

// Mock classes must be at the top level, after imports
class _MockSupabaseClient {
  dynamic from(String table) {
    return _MockQueryBuilder(table);
  }
}

class _MockQueryBuilder {
  final String table;
  String? areaTag;
  _MockQueryBuilder(this.table);
  dynamic select([String? columns]) => this;
  dynamic ilike(String column, String pattern) {
    if (column == 'area_tag') areaTag = pattern;
    return this;
  }
  dynamic eq(String column, dynamic value) => this;
  Future<List<Map<String, dynamic>>> order(String column) async {
    if (table == 'locations' && areaTag == '%Halifax%') {
      return [
        {'id': 1, 'name': 'Mock Location', 'area_tag': 'Halifax'}
      ];
    }
    return [];
  }
}

void main() {
  group('SupabaseService', () {
    test('fetchLocationsByFilters builds correct query for areaTag filter', () async {
      final mockClient = _MockSupabaseClient();
      final service = SupabaseService(client: mockClient);
      final result = await service.fetchLocationsByFilters(areaTag: 'Halifax');
      expect(result, isA<List>());
      expect(result.length, 1);
      expect(result[0]['name'], 'Mock Location');
    });

    test('fetchLocationsByFilters returns empty list for unknown areaTag', () async {
      final mockClient = _MockSupabaseClient();
      final service = SupabaseService(client: mockClient);
      final result = await service.fetchLocationsByFilters(areaTag: 'NonExistentTown');
      expect(result, isA<List>());
      expect(result, isEmpty);
    });
  });
}