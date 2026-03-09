import 'dart:io';
import 'package:build/build.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTE: web/drift_worker.js is also a generated file, but it can't go through
// build_runner because `dart compile js` writes directly to a file path.
// Recompile it manually after upgrading the `drift` package:
//
//   dart compile js -O2 -o web/drift_worker.js \
//       --packages .dart_tool/package_config.json \
//       -Dpackage:drift/wasm.dart
//
// Shorter version using a one-liner entry point already in the project:
//   echo "import 'package:drift/wasm.dart'; void main() => WasmDatabase.workerMainForOpen();" \
//       > web/_worker_entry.dart && \
//   dart compile js -O2 -o web/drift_worker.js web/_worker_entry.dart && \
//   rm web/_worker_entry.dart
// ─────────────────────────────────────────────────────────────────────────────

Builder protoBuilder(BuilderOptions options) => _ProtoBuilder();

class _ProtoBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    r'proto/{{}}.proto': [
      r'lib/proto/{{}}.pb.dart',
      r'lib/proto/{{}}.pbenum.dart',
      r'lib/proto/{{}}.pbjson.dart',
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // e.g. "proto/models.proto" → "models"
    final inputPath = buildStep.inputId.path;
    final baseName = inputPath.split('/').last.replaceAll('.proto', '');

    final protoc = _find(
      name: 'protoc',
      wingetSubPath: 'bin\\protoc.exe',
      wingetPackagePrefix: 'Google.Protobuf',
      pubCacheName: null,
      hint: 'winget install Google.Protobuf',
    );
    final plugin = _find(
      name: 'protoc-gen-dart',
      wingetSubPath: null,
      wingetPackagePrefix: null,
      pubCacheName: 'protoc-gen-dart',
      hint: 'dart pub global activate protoc_plugin',
    );

    final tempDir = await Directory.systemTemp.createTemp('proto_build_');
    try {
      final result = await Process.run(protoc, [
        '--dart_out=${tempDir.path}',
        '-I',
        'proto',
        '--plugin=protoc-gen-dart=$plugin',
        inputPath,
      ]);
      if (result.exitCode != 0) {
        throw Exception('protoc failed:\n${result.stderr}');
      }

      for (final ext in ['.pb.dart', '.pbenum.dart', '.pbjson.dart']) {
        final generated = File('${tempDir.path}/$baseName$ext');
        final outputId = AssetId(
          buildStep.inputId.package,
          'lib/proto/$baseName$ext',
        );
        // .pbserver.dart is only generated when the proto has gRPC services;
        // skip if the file wasn't produced.
        if (!generated.existsSync()) continue;
        final content = generated.readAsStringSync();
        await buildStep.writeAsString(outputId, content);
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  }
}

String _find({
  required String name,
  required String? wingetSubPath,
  required String? wingetPackagePrefix,
  required String? pubCacheName,
  required String hint,
}) {
  // 1. PATH
  final onPath = _which(name);
  if (onPath != null) return onPath;

  // 2. WinGet packages directory (Windows)
  if (wingetPackagePrefix != null &&
      wingetSubPath != null &&
      Platform.isWindows) {
    final base =
        '${Platform.environment['LOCALAPPDATA']}\\Microsoft\\WinGet\\Packages';
    final dir = Directory(base);
    if (dir.existsSync()) {
      for (final entry in dir.listSync()) {
        final leaf = entry.path.split(Platform.pathSeparator).last;
        if (leaf.startsWith(wingetPackagePrefix)) {
          final exe = File('${entry.path}\\$wingetSubPath');
          if (exe.existsSync()) return exe.path;
        }
      }
    }
  }

  // 3. Pub global cache
  if (pubCacheName != null) {
    final cache =
        Platform.environment['PUB_CACHE'] ??
        (Platform.isWindows
            ? '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache'
            : '${Platform.environment['HOME']}/.pub-cache');
    for (final candidate in [
      if (Platform.isWindows) '$cache\\bin\\$pubCacheName.bat',
      if (Platform.isWindows) '$cache\\bin\\$pubCacheName.exe',
      '$cache/bin/$pubCacheName',
    ]) {
      if (File(candidate).existsSync()) return candidate;
    }
  }

  throw StateError('"$name" not found. Install with: $hint');
}

String? _which(String name) {
  try {
    final r = Process.runSync(Platform.isWindows ? 'where' : 'which', [
      name,
    ], runInShell: true);
    if (r.exitCode == 0) {
      final first = (r.stdout as String).trim().split('\n').first.trim();
      if (first.isNotEmpty) return first;
    }
  } catch (_) {}
  return null;
}
