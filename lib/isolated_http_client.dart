library isolated_http_client;

import 'dart:io';
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
  final c = IsolatedHttpClient(Duration(seconds: 3), false);
  await c.get(host: "https://restcountries.eu/rest/v2/all").next(onValue: (body){
    print(body.bodyAsList);
  });

  await c.get(host: "https://countriesnow.space/api/v0.1/countries/population/cities").next(onValue: (body){
    print(body.body);
  });
  print('finish');
  exit(0);
}
