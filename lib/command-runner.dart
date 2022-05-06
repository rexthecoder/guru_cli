import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';

import 'package:pub_updater/pub_updater.dart';

/// The package name.
const packageName = 'guru_cli';

/// {@template guru_command_runner}
/// A [CommandRunner] for the Very Good CLI.
/// {@endtemplate}
class GuruCommandRunner extends CommandRunner<int> {
  /// {@macro guru_command_runner}
  GuruCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger ?? Logger(),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        super('guru', 'Guru Command Line Interface') {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addOption(
        'analytics',
        help: 'Toggle anonymous usage statistics.',
        allowed: ['true', 'false'],
        allowedHelp: {
          'true': 'Enable anonymous usage statistics',
          'false': 'Disable anonymous usage statistics',
        },
      )
      ..addSeparator('Guru commands:')
      ;
  }

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;

  final PubUpdater _pubUpdater;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final _argResults = parse(args);
      return await runCommand(_argResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    int? exitCode = ExitCode.unavailable.code;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }
    await _checkForUpdates();
    return exitCode;
  }

  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        _logger
          ..info('')
          ..info(
            '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
${lightYellow.wrap('Changelog:')} ${lightCyan.wrap('https://github.com/Guruopensource/guru_cli/releases/tag/v$latestVersion')}
Run ${lightCyan.wrap('dart pub global activate guru_cli')} to update''',
          );
      }
    } catch (_) {}
  }
}
