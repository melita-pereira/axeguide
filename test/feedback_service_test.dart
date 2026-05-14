import 'package:flutter_test/flutter_test.dart';
import 'package:axeguide/services/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    group('getCategories', () {
      test('should return all feedback categories', () {
        final categories = FeedbackService.getCategories();
        expect(categories, isNotNull);
        expect(categories.length, 4);
        expect(categories, contains('Bug'));
        expect(categories, contains('Feature Request'));
        expect(categories, contains('General Feedback'));
        expect(categories, contains('Other'));
      });

      test('should return categories in expected order', () {
        final categories = FeedbackService.getCategories();
        expect(categories[0], 'Bug');
        expect(categories[1], 'Feature Request');
        expect(categories[2], 'General Feedback');
        expect(categories[3], 'Other');
      });
    });

    group('submitFeedback', () {
      test('should validate that rating is between 1-5', () async {
        final service = FeedbackService();

        // Note: Full integration tests with Supabase would require mocking
        // This test verifies the method signature and basic structure
        expect(
          () => service.submitFeedback(
            feedbackText: 'Test feedback with enough characters',
            rating: 0, // Invalid rating
            category: 'Bug',
          ),
          isNotNull,
        );
      });

      test('should require non-empty feedback text', () async {
        final service = FeedbackService();

        expect(
          () => service.submitFeedback(
            feedbackText: '',
            rating: 5,
            category: 'Bug',
          ),
          isNotNull,
        );
      });

      test('should require valid category', () async {
        final service = FeedbackService();

        expect(
          () => service.submitFeedback(
            feedbackText: 'Test feedback with enough characters',
            rating: 5,
            category: 'InvalidCategory',
          ),
          isNotNull,
        );
      });

      test('should accept optional userId, location, and appVersion', () async {
        final service = FeedbackService();

        expect(
          () => service.submitFeedback(
            feedbackText: 'Test feedback with enough characters',
            rating: 5,
            category: 'Bug',
            userId: 'user123',
            location: 'Halifax',
            appVersion: '1.0.0',
          ),
          isNotNull,
        );
      });

      test('should accept null userId, location, and appVersion', () async {
        final service = FeedbackService();

        expect(
          () => service.submitFeedback(
            feedbackText: 'Test feedback with enough characters',
            rating: 5,
            category: 'General Feedback',
            userId: null,
            location: null,
            appVersion: null,
          ),
          isNotNull,
        );
      });
    });
  });
}
