import 'dart:async';
import 'dart:io';

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/helpers/errors.dart';
import 'package:yhat_app/models/branch.dart';
import 'package:yhat_app/models/build.dart';
import 'package:yhat_app/models/model.dart';
import 'package:yhat_app/models/notebook.dart';
import 'package:yhat_app/models/repository.dart';
import 'package:yhat_app/models/run.dart';
import 'package:yhat_app/models/signedUrl.dart';
import 'package:yhat_app/models/token.dart';
import 'package:yhat_app/models/user.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:http_parser/http_parser.dart';

String baseUrl = env['SERVER_BASE_URL']!;

class AuthClient extends http.BaseClient {
  final Token? token;
  http.Client inner = RetryClient(BrowserClient()..withCredentials = true);

  AuthClient({this.token});

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers[HttpHeaders.contentTypeHeader] =
        'application/json; charset=UTF-8';
    request.headers[HttpHeaders.acceptHeader] = 'application/json';
    if (token != null) {
      request.headers[HttpHeaders.authorizationHeader] =
          'Bearer ${token!.token}';
    }

    return inner.send(request);
  }
}

String formattedDate(DateTime date) {
  date = date.toLocal();
  DateTime now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    String time = DateFormat().add_jm().format(date);
    return "Today, $time";
  } else if (date.year == now.year &&
      date.month == now.month &&
      date.day == (now.day - 1)) {
    String time = DateFormat().add_jm().format(date);
    return "Yesterday, $time";
  }
  return DateFormat.yMMMMEEEEd().add_jm().format(date);
}

enum Method { Get, Post, Put, Delete }

class ModelParameter extends Equatable {
  ModelParameter({
    required this.modelId,
    this.runStart = 0,
    this.runOffset = 0,
  });
  final String modelId;
  final int runStart;
  final int runOffset;

  @override
  List<Object> get props {
    return [modelId];
  }
}

class RunListParameter extends Equatable {
  RunListParameter({
    required this.modelId,
    this.modelVersionId,
    required this.start,
    required this.offset,
  });

  final String modelId;
  final String? modelVersionId;
  final int start;
  final int offset;

  @override
  List<Object> get props {
    if (modelVersionId != null) {
      return [modelId, modelVersionId!, start, offset];
    } else {
      return [modelId, start, offset];
    }
  }
}

class API {
  final Reader read;
  API({required this.read});

  Future<List<Model>> fetchModelList(
      {int? offset = 0,
      int? length = 10,
      String? userId,
      bool mine = false}) async {
    try {
      String meSegment = mine == true ? "me" : "";
      String userIdSegment = userId != null ? "?user_id=$userId" : "";
      var uri = Uri.parse('$baseUrl/model/$meSegment$userIdSegment');
      String body =
          await request(method: Method.Get, isAuthenticated: mine, uri: uri);
      var list = jsonDecode(body) as List;
      List<Model> models = list.map((model) => Model.fromJson(model)).toList();
      return models;
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<Model> fetchModel({required String modelId}) async {
    try {
      var uri = Uri.parse('$baseUrl/model/$modelId');
      String body =
          await request(method: Method.Get, isAuthenticated: false, uri: uri);

      return Model.fromJson(jsonDecode(body));
    } on NotFoundException catch (e, _) {
      throw "Not able to find Model, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<Model> updateModel(
      {required String modelId,
      String? title,
      String? description,
      String? credits,
      String? releaseNotes}) async {
    try {
      Map<String, String> inputs = {};
      if (title != null) {
        inputs['title'] = title;
      }
      if (description != null) {
        inputs['description'] = description;
      }
      if (credits != null) {
        inputs['credits'] = credits;
      }
      if (releaseNotes != null) {
        inputs['releaseNotes'] = releaseNotes;
      }
      var putBody = jsonEncode(inputs);

      var uri = Uri.parse('$baseUrl/model/$modelId');
      String body = await request(
          method: Method.Put, isAuthenticated: true, uri: uri, body: putBody);
      return Model.fromJson(jsonDecode(body));
    } on NotFoundException catch (e, _) {
      throw "Not able to find Model, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<Model> deleteModel({
    required String modelId,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/model/$modelId');
      String body =
          await request(method: Method.Delete, isAuthenticated: true, uri: uri);
      return Model.fromJson(jsonDecode(body));
    } on NotFoundException catch (e, _) {
      throw "Not able to find Model, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<List<Run>> fetchRunList(
      {int offset = 0,
      int length = 10,
      String? modelId,
      String? buildId,
      String? userId}) async {
    try {
      Map<String, String> queryParam = {};
      if (modelId != null) {
        queryParam.addAll({"model_id": modelId});
      }
      if (buildId != null) {
        queryParam.addAll({"build_id": buildId});
      }
      if (userId != null) {
        queryParam.addAll({"user_id": userId});
      }
      var uri = Uri.parse('$baseUrl/run/');
      uri = Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          path: uri.path,
          queryParameters: queryParam);
      String body =
          await request(method: Method.Get, isAuthenticated: false, uri: uri);
      var list = jsonDecode(body) as List;
      List<Run> runs = list.map((run) => Run.fromJson(run)).toList();
      return runs;
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<List<SignedUrl>> createSignedUrl(
      {required String modelId, required String runId}) async {
    try {
      var uri = Uri.parse('$baseUrl/signed_url/$modelId?run_id=$runId');

      String body =
          await request(method: Method.Post, isAuthenticated: true, uri: uri);
      var list = jsonDecode(body) as List;
      List<SignedUrl> signedUrls =
          list.map((run) => SignedUrl.fromJson(run)).toList();

      return signedUrls;
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find Notebook, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<String> createS3Asset(
      {required SignedUrl signedUrl,
      required String fileName,
      required PlatformFile file}) async {
    try {
      var uri = Uri.parse(signedUrl.url);
      var req = http.MultipartRequest('POST', uri)
        ..fields.addAll(signedUrl.fields);
      req.files.add(http.MultipartFile.fromBytes('file', file.bytes!,
          filename: fileName, contentType: new MediaType('image', 'jpeg')));
      await req.send();
      // var streamedResponse = await req.send();
      // await http.Response.fromStream(streamedResponse);
      String bucket = signedUrl.url.split(".")[0].replaceAll("https://", "");
      return "s3://$bucket/${signedUrl.fields['key']}";
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find Notebook, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<Run> submitPredition(
      {required String modelId,
      required Map<String, dynamic> inputs,
      required String runId}) async {
    try {
      var uri = Uri.parse('$baseUrl/prediction/$modelId?run_id=$runId');
      var postBody = jsonEncode(inputs);

      String body = await request(
          method: Method.Post, isAuthenticated: true, uri: uri, body: postBody);

      return Run.fromJson(json.decode(body));
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find Notebook, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<bool> signup({required String email}) async {
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  Future<Token> createGithubToken({required String code}) async {
    try {
      var postBody = jsonEncode(<String, String>{
        'code': code,
      });
      var uri = Uri.parse('$baseUrl/user/login/github');
      String body = await request(
          method: Method.Post,
          isAuthenticated: false,
          uri: uri,
          body: postBody);
      return Token.fromJson(jsonDecode(body));
    } on TokenException catch (_) {
      throw "Not able to sign in. Please try again or click the ? for help or for early access info.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<User> fetchUser({required String userId}) async {
    try {
      var uri = Uri.parse('$baseUrl/user/$userId');
      String body =
          await request(method: Method.Get, isAuthenticated: false, uri: uri);
      return User.fromJson(jsonDecode(body));
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<String> request(
      {required Method method,
      required bool isAuthenticated,
      required Uri uri,
      String body = ''}) async {
    AuthClient? client;
    if (isAuthenticated) {
      Token? token = read(meController).token;
      if (token == null) throw TokenException(cause: 'Token not found');
      client = AuthClient(token: token);
    } else {
      client = AuthClient();
    }

    try {
      Response? response;
      if (method == Method.Get) {
        response = await client.get(uri);
      } else if (method == Method.Post) {
        response = await client.post(uri, body: body);
      } else if (method == Method.Put) {
        response = await client.put(uri, body: body);
      } else if (method == Method.Delete) {
        response = await client.delete(uri);
      } else {
        throw "Method $method not found";
      }
      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        throw TokenException(
            notifier: read(meController.notifier), shouldLogout: true);
      } else if (response.statusCode == HttpStatus.notFound) {
        throw NotFoundException();
      } else {
        throw HttpException('Response code ${response.statusCode}', uri: uri);
      }
    } finally {
      client.close();
    }
  }

  Future<Build> fetchBuild({required String buildId}) async {
    try {
      var uri = Uri.parse('$baseUrl/build/$buildId');
      String body =
          await request(method: Method.Get, isAuthenticated: false, uri: uri);
      return Build.fromJson(jsonDecode(body));
    } on NotFoundException catch (e, _) {
      throw "Not able to find build, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<String> fetchBuildLog({required String buildId}) async {
    try {
      var uri = Uri.parse('$baseUrl/build/log/$buildId');
      String body =
          await request(method: Method.Get, isAuthenticated: true, uri: uri);
      return body;
    } on NotFoundException catch (e, _) {
      throw "Not able to find build, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<User> fetchMe() async {
    try {
      var uri = Uri.parse('$baseUrl/user/me');
      String body =
          await request(method: Method.Get, isAuthenticated: true, uri: uri);
      return User.fromJson(jsonDecode(body));
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      read(meController.notifier).logout();
      throw "Not able to sign in, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<List<Repository>> fetchRepositoryList(
      {required String githubUsername}) async {
    try {
      var uri = Uri.parse('$baseUrl/repository/$githubUsername');
      String body =
          await request(method: Method.Get, isAuthenticated: true, uri: uri);
      List<Repository> repositoryList;
      repositoryList = (json.decode(body) as List)
          .map((i) => Repository.fromJson(i))
          .toList();
      return repositoryList;
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find GitHub User, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<List<Branch>> fetchBranchList(
      {required String githubUsername, required String repo}) async {
    try {
      var uri = Uri.parse('$baseUrl/repository/$githubUsername/$repo/branches');
      String body =
          await request(method: Method.Get, isAuthenticated: true, uri: uri);
      List<Branch> branchList;
      branchList =
          (json.decode(body) as List).map((i) => Branch.fromJson(i)).toList();
      return branchList;
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find GitHub User, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<List<Notebook>> fetchNotebookList(
      {required String githubUsername,
      required String repo,
      required String branch}) async {
    try {
      var uri = Uri.parse(
          '$baseUrl/repository/$githubUsername/$repo/$branch/notebooks');
      String body =
          await request(method: Method.Get, isAuthenticated: true, uri: uri);
      List<Notebook> notebookList;
      notebookList =
          (json.decode(body) as List).map((i) => Notebook.fromJson(i)).toList();
      return notebookList;
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find Notebook, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<Notebook> fetchNotebook(
      {required String githubUsername,
      required String repo,
      required String branch,
      required String notebook}) async {
    try {
      notebook = notebook.replaceAll("/", "|");
      var uri = Uri.parse(
          '$baseUrl/repository/$githubUsername/$repo/$branch/$notebook');
      String body =
          await request(method: Method.Get, isAuthenticated: true, uri: uri);
      return Notebook.fromJson(json.decode(body));
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find Notebook, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }

  Future<Build> createBuild(
      {required String githubUsername,
      required String repository,
      required String branch,
      required String notebook,
      String commit = ''}) async {
    try {
      notebook = notebook.replaceAll("/", "|");

      var postBody = jsonEncode(<String, String>{
        'github_username': githubUsername,
        'repository': repository,
        'branch': branch,
        'notebook': notebook,
        'commit': commit,
      });

      var uri = Uri.parse('$baseUrl/build/');
      String body = await request(
          method: Method.Post, isAuthenticated: true, uri: uri, body: postBody);
      return Build.fromJson(json.decode(body));
    } on TokenException catch (e, _) {
      throw "Not able to sign in, please try again.";
    } on NotFoundException catch (e, _) {
      throw "Not able to find Notebook, please try again.";
    } on Exception catch (e, st) {
      await Sentry.captureException(
        e,
        stackTrace: st,
      );
      throw "Not able to connect to server, please again try later.";
    }
  }
}
