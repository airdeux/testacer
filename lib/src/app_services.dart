import 'access/access_repository.dart';
import 'auth/auth_service.dart';
import 'auth/email_link_controller.dart';
import 'import/file_picker_service.dart';
import 'questions/question_set_repository.dart';
import 'quiz/progress_repository.dart';
import 'settings/user_settings.dart';

/// Everything the screens use, created in main.dart (Firebase) or in the
/// tests (fakes).
class AppServices {
  const AppServices({
    required this.auth,
    required this.access,
    required this.emailLinks,
    required this.questionSets,
    required this.progress,
    required this.settings,
    required this.filePicker,
  });

  final AuthService auth;
  final AccessRepository access;
  final EmailLinkController emailLinks;
  final QuestionSetRepository questionSets;
  final ProgressRepository progress;
  final UserSettingsRepository settings;
  final FilePickerService filePicker;
}
