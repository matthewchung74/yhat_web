import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/helpers/errors.dart';
import 'package:yhat_app/helpers/ui.dart';
import 'package:yhat_app/main.dart';
import 'package:yhat_app/models/build.dart';
import 'package:yhat_app/models/token.dart';
import 'package:yhat_app/page/model_run_page.dart';
import 'package:yhat_app/widgets/my_app_bar.dart';
import 'package:yhat_app/widgets/snack_bar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/flutter.dart';
import 'package:xterm/theme/terminal_style.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String baseUrl = env['SERVER_BASE_URL']!;

const String NotStarted = "NotStarted";
const String Started = "Started";
const String Running = "Running";
const String Error = "Error";
const String Cancelled = "Cancelled";
const String Cancelling = "Cancelling";
const String Finished = "Finished";

final runningProvider = StateProvider.autoDispose<String>((ref) {
  return NotStarted;
});

final buildProvider =
    FutureProvider.autoDispose.family<Build, String>((ref, buildId) async {
  Build build = await ref.read(apiProvider).fetchBuild(buildId: buildId);

  if (build.status == BuildStatus.Finished ||
      build.status == BuildStatus.Error) {
    String buildLog =
        await ref.read(apiProvider).fetchBuildLog(buildId: buildId);
    buildLog = buildLog.substring(1, buildLog.length - 1);
    buildLog = buildLog.replaceAll("\\r\\n", "\r\n");
    build.buildLog = buildLog;
  } else if (build.status == BuildStatus.Started) {
    build.buildLog =
        " \r\n\r\nBuilding started in another browser, we will send an email to your Github email when it is done. \r\n";
  }

  return build;
});

final provider = StateNotifierProvider.autoDispose
    .family<StartBuildNotifier, AsyncValue<Map<String, dynamic>>, String>(
        (ref, buildId) {
  return StartBuildNotifier(ref: ref, buildId: buildId);
});

class StartBuildNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  StartBuildNotifier({required this.ref, required this.buildId})
      : super(AsyncLoading());

  String buildId;
  final AutoDisposeProviderRefBase ref;
  WebSocketChannel? _startChannel;
  WebSocketChannel? _cancelChannel;
  void restart() async {
    final build = await ref.read(buildProvider(buildId).future);

    Build newBuild = await ref.read(apiProvider).createBuild(
        githubUsername: build.githubUsername,
        repository: build.repository,
        branch: build.branch,
        notebook: build.notebook,
        commit: '');
    buildId = newBuild.id;

    await start();
  }

  Future<void> start() async {
    if (!mounted) {
      return;
    }

    state = AsyncLoading();
    final runningProviderState = ref.read(runningProvider).state;
    try {
      if (runningProviderState == NotStarted ||
          runningProviderState == Cancelled ||
          runningProviderState == Error) {
        await startBuild();
      } else if (runningProviderState == Running) {
        await cancelBuild();
      } else if (runningProviderState == Finished) {
        await runModel();
      }
    } on Exception {
    } finally {}
  }

  Future sleep() {
    return new Future.delayed(const Duration(seconds: 3), () => "1");
  }

  Future<void> runModel() async {
    state = AsyncLoading();
    final _buildProvider = ref.watch(buildProvider(buildId));
    _buildProvider.when(
        data: (data) {
          ref
              .read(navigationStackProvider)
              .push(MaterialPage(child: ModelRunPage(modelId: data.modelId)));
        },
        loading: () {},
        error: (err, stack) => {});
  }

  Future<void> cancelBuild() async {
    // var channel;
    final _runningProvider = ref.read(runningProvider);

    try {
      _runningProvider.state = Cancelling;

      String wsUrl =
          baseUrl.replaceAll("http:", "ws:").replaceAll("https:", "wss:");
      _cancelChannel = WebSocketChannel.connect(
        Uri.parse("$wsUrl/ws"),
      );

      ref.onDispose(() {
        _cancelChannel?.sink.close();
      });

      Token? token = ref.read(meController).token;
      if (token == null) throw TokenException(cause: 'Token not found');

      var message = jsonEncode(<String, String>{
        'build_id': buildId,
        'jwt': token.token,
        'command': "cancel",
      });

      _cancelChannel?.sink.add(message);
      await sleep();
    } catch (e) {
      state = AsyncError(e);
    } finally {
      _cancelChannel?.sink.close();
    }
  }

  Future<void> startBuild({int retryCount = 0}) async {
    if (retryCount > 10) {
      state =
          AsyncError("Not able to connect to server, please again try later.");
      return;
    }

    final _runningProvider = ref.read(runningProvider);
    // var channel;
    try {
      _runningProvider.state = Started;
      String wsUrl =
          baseUrl.replaceAll("http:", "ws:").replaceAll("https:", "wss:");
      _startChannel = WebSocketChannel.connect(
        Uri.parse("$wsUrl/ws"),
      );

      ref.onDispose(() {
        _startChannel?.sink.close();
      });

      Token? token = ref.read(meController).token;
      if (token == null) throw TokenException(cause: 'Token not found');

      var message = jsonEncode(<String, String>{
        'build_id': buildId,
        'jwt': token.token,
        'command': "start",
      });

      _startChannel?.sink.add(message);

      await for (final value in _startChannel!.stream) {
        final data = jsonDecode(value);
        state = AsyncData(data);
        _runningProvider.state = data['state'];
      }

      if (_startChannel?.closeCode == 1006) {
        throw WebSocketChannelException();
      }
    } on WebSocketChannelException catch (e, _) {
      Future.delayed(Duration(milliseconds: 3000)).then((_) async {
        await startBuild(retryCount: retryCount + 1);
      });
    } catch (e) {
      state = AsyncError(e);
    } finally {
      _startChannel?.sink.close();
    }
  }
}

class BuildStartPage extends ConsumerStatefulWidget {
  final String buildId;
  const BuildStartPage({Key? key, required this.buildId});

  @override
  _BuildStartPage createState() => _BuildStartPage(buildId: buildId);
}

//ignore: must_be_immutable
class _BuildStartPage extends ConsumerState<BuildStartPage> {
  final String buildId;
  var terminal = Terminal(maxLines: 10000);

  _BuildStartPage({required this.buildId});

  @override
  void initState() {
    super.initState();
  }

  void _downloadLog() {
    StringBuffer buffer = StringBuffer();
    for (var i = 0; i < terminal.buffer.lines.length; i++) {
      buffer.write(terminal.buffer.lines[i].data.toString() + "\n");
    }
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String urlData =
        "data:application/octet-stream;base64,${stringToBase64.encode(buffer.toString())}";
    launchURLBrowser(url: urlData, target: "_blank");
  }

  Widget _headerWidget({required Build? build}) {
    final notifier = ref.read(provider(buildId).notifier);
    final String running = ref.watch(runningProvider).state;
    String runningText = '';
    Function()? runningFunction;
    if (build == null) {
      runningText = "";
      runningFunction = null;
    } else if (build.status == BuildStatus.Error ||
        build.status == BuildStatus.Finished) {
    } else {
      if (running == Started) {
        runningText = "Cancel Build";
        runningFunction = null;
      } else if (running == Running) {
        runningText = "Cancel Build";
        runningFunction = notifier.start;
      } else if (running == Cancelled || running == NotStarted) {
        runningText = "Start Build";
        runningFunction = notifier.start;
      } else if (running == Error) {
        runningText = "Retry Build";
        runningFunction = notifier.restart;
      } else if (running == Cancelling) {
        runningText = "Cancel Build";
        runningFunction = null;
      } else if (running == Finished) {
        runningText = "Run Model";
        runningFunction = notifier.start;
      }
    }

    var screenWidth = MediaQuery.of(context).size.width;
    double calculatedButtonFontSize =
        (20 * screenWidth / 600) > 20 ? 20 : 20 * screenWidth / 800;

    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  flex: 2,
                  child: Text(
                    build != null ? build.prettyNotebookName : '',
                    style: Theme.of(context)
                        .textTheme
                        .headline3!
                        .copyWith(fontSize: 24),
                    overflow: TextOverflow.ellipsis,
                  )),
              SizedBox(
                height: 8,
              ),
              Flexible(
                  flex: 1,
                  child: ElevatedButton(
                      onPressed: runningFunction,
                      style: Theme.of(context).elevatedButtonTheme.style,
                      child: SizedBox(
                        width: 160,
                        height: 40,
                        child: Center(
                          child: Text(runningText,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5!
                                  .copyWith(
                                      color: Colors.white,
                                      fontSize: calculatedButtonFontSize)),
                        ),
                      ))),
            ],
          ),
          SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SelectableText(
                      "BUILD ID: ",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2!
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    SelectableText(
                      buildId.split("-")[0],
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]);
  }

  Widget _buildBodyHeaderWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("         "),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("BUILD LOG",
              style: Theme.of(context)
                  .textTheme
                  .headline5!
                  .copyWith(color: Color.fromRGBO(26, 36, 54, 1))),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextButton(
              onPressed: () {
                _downloadLog();
              },
              style: Theme.of(context).textButtonTheme.style!.copyWith(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.fromLTRB(0, 0, 0, 0))),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'EXPORT',
                  textAlign: TextAlign.right,
                  style: Theme.of(context)
                      .textTheme
                      .headline5!
                      .copyWith(color: Colors.blue.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        )
      ],
    );
  }

  Widget _build() {
    final notifier = ref.watch(provider(buildId));

    return Expanded(
        child: notifier.when(
      data: (data) {
        final message = data["message"];
        terminal.write(message);
        return TerminalView(
            key: ValueKey("TerminalView-$buildId"),
            terminal: terminal,
            style: TerminalStyle(fontFamily: ["Cascadia Mono"]));
      },
      loading: () {
        return Stack(
          children: [
            LinearProgressIndicator(),
            TerminalView(
                terminal: terminal,
                style: TerminalStyle(fontFamily: ["Cascadia Mono"]))
          ],
        );
      },
      error: (error, st) {
        return SnackBarWidget(
          snackBarStatus: SnackBarStatus.Alert,
          message: error.toString(),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final _buildProvider = ref.watch(buildProvider(buildId));

    return Scaffold(
        appBar: myAppBar(context: context, ref: ref),
        body: Padding(
            padding: const EdgeInsets.all(0.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: _buildProvider.when(data: (data) {
                  return _headerWidget(build: data);
                }, loading: () {
                  return _headerWidget(build: null);
                }, error: (error, st) {
                  return _headerWidget(build: null);
                }),
              ),
              Divider(),
              _buildBodyHeaderWidget(),
              _buildProvider.when(data: (data) {
                if (data.buildLog != null) {
                  terminal.write(data.buildLog!);
                  return Expanded(
                    child: TerminalView(
                        key: ValueKey("TerminalView-$buildId"),
                        terminal: terminal,
                        style: TerminalStyle(fontFamily: ["Cascadia Mono"])),
                  );
                } else {
                  return _build();
                }
              }, loading: () {
                return _build();
              }, error: (error, st) {
                return SnackBarWidget(
                  snackBarStatus: SnackBarStatus.Alert,
                  message: error.toString(),
                );
              })
            ])));
  }
}
