import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class FeedbackService {
  final SupabaseClient client;

  FeedbackService({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  /// Submit feedback to Supabase
  /// Returns true if submission was successful, false otherwise
  Future<bool> submitFeedback({
    required String feedbackText,
    required int rating,
    required String category,
    String? userId,
    String? location,
    String? appVersion,
  }) async {
    try {
      await client.from('feedback').insert({
        'feedback_text': feedbackText,
        'rating': rating,
        'category': category,
        'user_id': userId,
        'location': location,
        'app_version': appVersion,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  /// Get feedback categories
  static List<String> getCategories() {
    return ['Bug', 'Feature Request', 'General Feedback', 'Other'];
  }
}
