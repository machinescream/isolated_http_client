library isolated_http_client;

import 'dart:io';

import 'package:http/http.dart';
import 'package:isolated_http_client/src/isolated_http_client.dart';
import 'package:worker_manager/worker_manager.dart';

export 'package:worker_manager/worker_manager.dart';
export 'src/exceptions.dart';
export 'src/http_method.dart';
export 'src/isolated_http_client.dart';
export 'src/requests.dart';
export 'src/response.dart';
export 'src/utils.dart';

Future<void> main() async {
  await Executor().warmUp();
  final c = HttpClientIsolated();
  final file = File('/Users/danielsurnin/3.mp4');
  final r = await c.filePost(
    host: 'http://5.101.179.150:4000',
    path: 'content',
    file: await MultipartFile.fromPath('file', file.path),
  );
  print(r);
  exit(0);
}
