import 'dart:developer';
import 'package:uuid/uuid.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inference_app/controller/providers.dart';
import 'package:inference_app/models/branch.dart';
import 'package:inference_app/models/build.dart';
import 'package:inference_app/models/notebook.dart';
import 'package:inference_app/models/repository.dart';
import 'package:inference_app/models/user.dart';
import 'package:inference_app/page/build_start_page.dart';
import 'package:inference_app/widgets/my_app_bar.dart';
import 'package:inference_app/widgets/snack_bar.dart';

import '../main.dart';

//ignore: must_be_immutable
class BuildNbsParameter extends Equatable {
  final String githubUrl;
  Repository? selectedRepository;
  Branch? selectedBranch;
  Notebook? selectedNotebook;
  BuildNbsParameter({
    this.githubUrl = '',
    this.selectedRepository,
    this.selectedBranch,
    this.selectedNotebook,
  });

  @override
  List<Object> get props {
    return [];
  }

  BuildNbsParameter clone({
    String? githubUrl,
    Repository? selectedRepository,
    Branch? selectedBranch,
    Notebook? selectedNotebook,
  }) {
    return BuildNbsParameter(
      githubUrl: githubUrl != null ? githubUrl : this.githubUrl,
      selectedRepository: selectedRepository != null
          ? selectedRepository
          : this.selectedRepository,
      selectedBranch:
          selectedBranch != null ? selectedBranch : this.selectedBranch,
      selectedNotebook:
          selectedNotebook != null ? selectedNotebook : this.selectedNotebook,
    );
  }
}

//ignore: must_be_immutable
class BuildNbsNotifierResponse extends Equatable {
  BuildNbsNotifierResponse({
    required this.user,
    this.repositories,
    this.branches,
    this.notebooks,
    this.selectedRepository,
    this.selectedBranch,
    this.selectedNotebook,
    this.uploaded,
    required this.githubUrl,
  });
  final String user;
  List<Repository>? repositories;
  List<Branch>? branches;
  List<Notebook>? notebooks;
  Repository? selectedRepository;
  Branch? selectedBranch;
  Notebook? selectedNotebook;
  bool? uploaded;
  final String githubUrl;
  @override
  List<Object> get props {
    return [user, githubUrl];
  }
}

final provider = StateNotifierProvider.autoDispose<BuildNbsNotifier,
    AsyncValue<BuildNbsNotifierResponse>>((ref) {
  return BuildNbsNotifier(read: ref.read);
});

class BuildNbsNotifier
    extends StateNotifier<AsyncValue<BuildNbsNotifierResponse>> {
  BuildNbsNotifier({required this.read}) : super(AsyncLoading());

  final Reader read;
  BuildNbsParameter? oldParam;
  BuildNbsNotifierResponse? oldData;

  Future<void> onGithubUrlChanged(String githubUrl) async {
    BuildNbsParameter param = BuildNbsParameter(githubUrl: githubUrl);
    await updateFields(param: param);
  }

  Future<void> onRepositoryChanged(String? selectedRepository) async {
    Repository? repository;
    if (oldData?.repositories != null) {
      repository = oldData!.repositories!
          .firstWhere((element) => element.name == selectedRepository);
    }

    BuildNbsParameter param = BuildNbsParameter(
        githubUrl: oldParam != null ? oldParam!.githubUrl : '',
        selectedRepository: repository);

    await updateFields(param: param);
  }

  Future<void> onBranchChanged(String? selectedBranch) async {
    Branch? branch;
    if (oldData?.branches != null) {
      branch = oldData!.branches!
          .firstWhere((element) => element.name == selectedBranch);
      if (branch.numberNotebooks == 0) {
        return;
      }
    }

    BuildNbsParameter param = BuildNbsParameter(
      githubUrl: oldParam != null ? oldParam!.githubUrl : '',
      selectedRepository: oldData != null ? oldData!.selectedRepository : null,
      selectedBranch: branch,
    );

    await updateFields(param: param);
  }

  Future<void> onNotebookChanged(String? selectedNotebook) async {
    Notebook? notebook;
    if (oldData?.notebooks != null) {
      notebook = oldData!.notebooks!
          .firstWhere((element) => element.name == selectedNotebook!);

      if (notebook.size != null && notebook.size! > 1000000) {
        return;
      }
    }

    BuildNbsParameter param = BuildNbsParameter(
      githubUrl: oldParam != null ? oldParam!.githubUrl : '',
      selectedRepository: oldData != null ? oldData!.selectedRepository : null,
      selectedBranch: oldData != null ? oldData!.selectedBranch : null,
      selectedNotebook: notebook,
    );

    await updateFields(param: param);
  }

  Future<void> onUploadNotebook() async {
    try {
      if (oldData != null) {
        state = AsyncLoading();

        String githubUsername = oldData!.user;
        String repository = oldData!.selectedRepository!.name;
        String branch = oldData!.selectedBranch!.name;
        String notebook = oldData!.selectedNotebook!.name;
        String commit = oldData!.selectedBranch!.commit!;

        Build build = await read(apiProvider).createBuild(
            githubUsername: githubUsername,
            repository: repository,
            branch: branch,
            notebook: notebook,
            commit: commit);
        state = AsyncData(oldData!);

        read(navigationStackProvider).push(MaterialPage(
            key: ValueKey("ModelInstall_${build.id}_${Uuid().v1()}"),
            child: BuildStartPage(
              buildId: build.id,
            )));
      } else {
        assert(true);
      }
    } catch (e) {
      state = AsyncError(e);
    }
  }

  Map<String, String> parseGithubUrl(String githubUrl, User user) {
    Uri uri = Uri.parse(githubUrl);
    if (uri.isAbsolute) {
      if (!uri.host.contains("github.com")) {
        throw "Could not find Github Organization or User";
      } else if (uri.pathSegments.length < 5) {
        throw "Could not find Github Organization or User";
      } else if (uri.pathSegments[uri.pathSegments.length - 1]
              .endsWith('ipynb') ==
          false) {
        throw "Could not find Notebook";
      }
      return {
        "githubUrl": githubUrl,
        "githubUsername": uri.pathSegments[0],
        "selectedRepository": uri.pathSegments[1],
        "selectedBranch": uri.pathSegments[3],
        "selectedNotebook":
            uri.pathSegments.sublist(4, uri.pathSegments.length).join("/")
      };
    } else if (uri.pathSegments.length > 1) {
      throw "Could not find Github Organization or User";
    } else if (uri.pathSegments.length == 1) {
      return {"githubUsername": uri.pathSegments[0]};
    } else {
      return {"githubUsername": user.githubUsername!};
    }
  }

  Future<Map<String, dynamic>> parseParameters(
      {required BuildNbsParameter param}) async {
    Map<String, dynamic> ret = {};

    User user = read(meController);
    String githubUsername = '';
    Repository? selectedRepository;
    Branch? selectedBranch;
    Notebook? selectedNotebook;

    try {
      final ret = parseGithubUrl(param.githubUrl, user);

      githubUsername = ret['githubUsername']!;

      if (ret.containsKey("selectedRepository")) {
        param.selectedRepository = Repository(
            fullName: '',
            name: ret['selectedRepository']!,
            defaultBranch: '',
            id: '',
            private: false);
      }
      if (ret.containsKey("selectedBranch")) {
        param.selectedBranch = Branch(name: ret['selectedBranch']!);
      }
      if (ret.containsKey("selectedNotebook")) {
        param.selectedNotebook = Notebook(name: ret['selectedNotebook']!);
      }
    } catch (e) {
      oldData = BuildNbsNotifierResponse(
          user: '',
          githubUrl: param.githubUrl,
          repositories: null,
          selectedRepository: null);
      throw e;
    }

    List<Repository> repositories;
    try {
      repositories = await read(apiProvider)
          .fetchRepositoryList(githubUsername: githubUsername);
    } on String catch (exception) {
      oldData = BuildNbsNotifierResponse(
          user: githubUsername, githubUrl: param.githubUrl);
      throw exception;
    }

    if (repositories.length == 0) {
      oldData = BuildNbsNotifierResponse(
          user: githubUsername, githubUrl: param.githubUrl);
      throw 'User has no public repositories';
    }

    if (param.selectedRepository == null) {
      selectedRepository = repositories[0];
    } else {
      selectedRepository = repositories.firstWhere(
          (element) => param.selectedRepository?.name == element.name);
    }

    // fetch branch
    List<Branch> branches = await read(apiProvider).fetchBranchList(
        githubUsername: githubUsername, repo: selectedRepository.name);

    selectedRepository.numBranches = branches.length;
    if (branches.length == 0) {
      oldData = BuildNbsNotifierResponse(
          user: githubUsername,
          githubUrl: param.githubUrl,
          repositories: repositories,
          selectedRepository: selectedRepository);
      throw 'Repository has no public branches';
    }

    if (param.selectedBranch == null) {
      selectedBranch = branches[0];
    } else {
      selectedBranch = branches
          .firstWhere((element) => element.name == param.selectedBranch?.name);
    }

    List<Notebook> notebooks = await read(apiProvider).fetchNotebookList(
        githubUsername: githubUsername,
        repo: selectedRepository.name,
        branch: selectedBranch.name);

    selectedBranch.numberNotebooks = notebooks.length;

    if (notebooks.length > 0) {
      if (param.selectedNotebook == null) {
        selectedNotebook = notebooks[0];
      } else {
        selectedNotebook = param.selectedNotebook;
      }
    }
    ret['githubUsername'] = githubUsername;
    ret['repositories'] = repositories;
    ret['branches'] = branches;
    ret['notebooks'] = notebooks;
    ret['selectedRepository'] = selectedRepository;
    ret['selectedBranch'] = selectedBranch;
    ret['selectedNotebook'] = selectedNotebook;
    ret['githubUrl'] = githubUsername != '' ? githubUsername : param.githubUrl;

    return ret;
  }

  Future<void> updateFields({required BuildNbsParameter param}) async {
    if (!mounted) return;

    state = AsyncLoading();
    try {
      Map<String, dynamic> parsed = await parseParameters(param: param);
      oldData = BuildNbsNotifierResponse(
        user: parsed['githubUsername']!,
        githubUrl: parsed['githubUrl'],
        repositories: parsed['repositories'] as List<Repository>,
        branches: parsed['branches'] as List<Branch>,
        notebooks: parsed['notebooks'] as List<Notebook>,
        selectedRepository: parsed['selectedRepository'],
        selectedBranch: parsed['selectedBranch'],
        selectedNotebook: parsed['selectedNotebook'],
      );

      if (!mounted) return;
      state = AsyncData(oldData!);
    } catch (e) {
      state = AsyncError(e);
    } finally {
      oldParam = param;
    }
  }
}

class BuildNbsPage extends ConsumerStatefulWidget {
  final String? githubUrl;
  const BuildNbsPage({this.githubUrl});
  @override
  _BuildNbsPage createState() => _BuildNbsPage(githubUrl: githubUrl);
}

class _BuildNbsPage extends ConsumerState<BuildNbsPage> {
  late TextEditingController githubUrlController;
  final String? githubUrl;

  _BuildNbsPage({this.githubUrl});

  @override
  void initState() {
    super.initState();
    githubUrlController = TextEditingController();
    Future.microtask(() {
      BuildNbsParameter param =
          BuildNbsParameter(githubUrl: githubUrl != null ? githubUrl! : '');
      ref.read(provider.notifier).updateFields(param: param);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(provider);
    final notifier = ref.watch(provider.notifier);

    return Scaffold(
        appBar: myAppBar(context: context, ref: ref),
        body: Container(
            width: double.infinity,
            child: controller.when(data: (data) {
              return BuildNbsWidget(
                githubUrlController: githubUrlController,
                githubUrl: data.githubUrl,
                repositories: data.repositories,
                branches: data.branches,
                notebooks: data.notebooks,
                selectedRepository: data.selectedRepository,
                selectedBranch: data.selectedBranch,
                selectedNotebook: data.selectedNotebook,
                onGithubUrlChanged: notifier.onGithubUrlChanged,
                onBranchChanged: notifier.onBranchChanged,
                onRepositoryChanged: notifier.onRepositoryChanged,
                onNotebookChanged: notifier.onNotebookChanged,
                onUploadNotebook: notifier.onUploadNotebook,
              );
            }, loading: () {
              var data = (notifier.oldData != null) ? notifier.oldData! : null;
              return Stack(
                children: [
                  LinearProgressIndicator(),
                  BuildNbsWidget(
                    githubUrlController: githubUrlController,
                    githubUrl: data?.githubUrl,
                    repositories: data?.repositories,
                    branches: data?.branches,
                    notebooks: data?.notebooks,
                    selectedRepository: data?.selectedRepository,
                    selectedBranch: data?.selectedBranch,
                    selectedNotebook: data?.selectedNotebook,
                    onGithubUrlChanged: notifier.onGithubUrlChanged,
                    onBranchChanged: null,
                    onRepositoryChanged: null,
                    onNotebookChanged: null,
                    onUploadNotebook: null,
                  )
                ],
              );
            }, error: (error, st) {
              debugger();
              if (error ==
                  "Not able to connect to server, please again try later.") {
                return SnackBarWidget(
                  snackBarStatus: SnackBarStatus.Alert,
                  message: error.toString(),
                );
              }
              var data = (notifier.oldData != null) ? notifier.oldData! : null;
              return BuildNbsWidget(
                githubUrlController: githubUrlController,
                githubUrl: data?.githubUrl,
                repositories: data?.repositories,
                branches: data?.branches,
                notebooks: data?.notebooks,
                selectedRepository: data?.selectedRepository,
                selectedBranch: data?.selectedBranch,
                selectedNotebook: data?.selectedNotebook,
                onGithubUrlChanged: notifier.onGithubUrlChanged,
                onBranchChanged: notifier.onBranchChanged,
                onRepositoryChanged: notifier.onRepositoryChanged,
                onNotebookChanged: notifier.onNotebookChanged,
                onUploadNotebook: null,
                message: error.toString(),
                snackBarStatus: SnackBarStatus.Alert,
              );
            })));
  }
}

//ignore: must_be_immutable
class BuildNbsWidget extends StatelessWidget {
  // _BuildNbsWidgetState({
  BuildNbsWidget({
    required this.githubUrlController,
    required this.githubUrl,
    required this.repositories,
    required this.branches,
    required this.notebooks,
    required this.selectedRepository,
    required this.selectedBranch,
    required this.selectedNotebook,
    required this.onGithubUrlChanged,
    required this.onRepositoryChanged,
    required this.onBranchChanged,
    required this.onNotebookChanged,
    required this.onUploadNotebook,
    this.message,
    this.snackBarStatus,
  });

  final TextEditingController githubUrlController;
  final String? githubUrl;
  final List<Repository>? repositories;
  final List<Branch>? branches;
  final List<Notebook>? notebooks;
  Repository? selectedRepository;
  Branch? selectedBranch;
  Notebook? selectedNotebook;
  final String? message;
  final SnackBarStatus? snackBarStatus;
  final Function(String)? onGithubUrlChanged;
  final Function(String?)? onRepositoryChanged;
  final Function(String?)? onBranchChanged;
  final Function(String?)? onNotebookChanged;
  final Function()? onUploadNotebook;

  @override
  Widget build(BuildContext context) {
    if (message != null && snackBarStatus != null) {
      Future.microtask(() {
        showSnackBar(
            context: context, message: message!, status: snackBarStatus!);
      });
    }
    var screenWidth = MediaQuery.of(context).size.width;

    double calculatedButtonFontSize =
        (20 * screenWidth / 600) > 20 ? 20 : 20 * screenWidth / 800;

    githubUrlController.text = githubUrl != null ? githubUrl! : '';

    return Container(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Enter a GitHub URL or search by organization or user",
                    style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.left,
                  ),
                  TextField(
                    autofocus: false,
                    style: Theme.of(context).textTheme.bodyText1,
                    enabled: true,
                    controller: githubUrlController,
                    onSubmitted: onGithubUrlChanged,
                    decoration: InputDecoration(
                      hintText: "hit enter to update",
                      labelText: "",
                      errorText: message,
                      suffix: TextButton(
                          onPressed: null,
                          child: Text.rich(TextSpan(
                              text: "press enter",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2!
                                  .copyWith(color: Colors.grey, fontSize: 12),
                              children: <InlineSpan>[
                                TextSpan(
                                  text: '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText2!
                                      .copyWith(
                                          color: Colors.grey, fontSize: 16),
                                )
                              ]))),
                    ),
                  ),
                  SizedBox(
                    height: 26,
                  ),
                  Text(
                    "Repository",
                    style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.left,
                  ),
                  DropdownButton<String>(
                      value: (selectedRepository != null)
                          ? selectedRepository!.name
                          : "REPOSITORY NAME",
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: Theme.of(context).textTheme.bodyText1,
                      underline: Container(
                        height: 2,
                        color: (onRepositoryChanged != null)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      onChanged:
                          repositories != null ? onRepositoryChanged : null,
                      items: (repositories != null)
                          ? repositories!.map<DropdownMenuItem<String>>(
                              (Repository repository) {
                              if (repository.numBranches != null &&
                                  repository.numBranches == 0) {
                                return DropdownMenuItem<String>(
                                    value: repository.name,
                                    child: Text(
                                        "${repository.name} (no branches)",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2!
                                            .copyWith(color: Colors.red)));
                              } else {
                                return DropdownMenuItem<String>(
                                    value: repository.name,
                                    child: Text(repository.name));
                              }
                            }).toList()
                          : ["REPOSITORY NAME"].map<DropdownMenuItem<String>>(
                              (String repository) {
                              return DropdownMenuItem<String>(
                                  value: repository, child: Text(repository));
                            }).toList()),
                  SizedBox(
                    height: 26,
                  ),
                  Text(
                    "Branch",
                    style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.left,
                  ),
                  DropdownButton<String>(
                      value: (selectedBranch != null)
                          ? selectedBranch!.name
                          : "BRANCH NAME",
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: Theme.of(context).textTheme.bodyText1,
                      underline: Container(
                          height: 2,
                          color: (onBranchChanged != null)
                              ? Colors.blue
                              : Colors.grey),
                      onChanged: branches != null ? onBranchChanged : null,
                      items: (branches != null)
                          ? branches!
                              .map<DropdownMenuItem<String>>((Branch branch) {
                              if (branch.numberNotebooks == 0) {
                                return DropdownMenuItem<String>(
                                    value: branch.name,
                                    child: Text("${branch.name} (no notebooks)",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2!
                                            .copyWith(color: Colors.red)));
                              } else {
                                return DropdownMenuItem<String>(
                                    value: branch.name,
                                    child: Text(
                                      branch.name,
                                    ));
                              }
                            }).toList()
                          : ["BRANCH NAME"]
                              .map<DropdownMenuItem<String>>((String branch) {
                              return DropdownMenuItem<String>(
                                  value: branch, child: Text(branch));
                            }).toList()),
                  SizedBox(
                    height: 26,
                  ),
                  Text(
                    "Notebook",
                    style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.left,
                  ),
                  DropdownButton<String>(
                    value: (selectedNotebook != null)
                        ? selectedNotebook!.name
                        : "NOTEBOOK NAME",
                    icon: const Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    style: Theme.of(context).textTheme.bodyText1,
                    underline: Container(
                        height: 2,
                        color: (onNotebookChanged != null)
                            ? Colors.blue
                            : Colors.grey),
                    onChanged: notebooks != null ? onNotebookChanged : null,
                    items: notebooks != null
                        ? notebooks!
                            .map<DropdownMenuItem<String>>((Notebook notebook) {
                            if (notebook.size != null &&
                                notebook.size! > 1000000) {
                              return DropdownMenuItem<String>(
                                  value: notebook.name,
                                  child: Text(
                                      "${notebook.name} (${double.parse((notebook.size! / 1000000).toStringAsFixed(1))}M) (too large, must be under 1M)",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2!
                                          .copyWith(color: Colors.red)));
                            } else {
                              return DropdownMenuItem<String>(
                                  value: notebook.name,
                                  child: Text(notebook.name));
                            }
                          }).toList()
                        : ["NOTEBOOK NAME"]
                            .map<DropdownMenuItem<String>>((String notebook) {
                            return DropdownMenuItem<String>(
                                value: notebook, child: Text(notebook));
                          }).toList(),
                  ),
                  SizedBox(
                    height: 26,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: selectedNotebook == null ||
                                    (selectedNotebook?.size != null &&
                                        selectedNotebook!.size! > 1000000)
                                ? null
                                : onUploadNotebook,
                            style: Theme.of(context).elevatedButtonTheme.style,
                            child: SizedBox(
                              width: 220,
                              height: 40,
                              child: Center(
                                child: Text("Upload Notebook",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5!
                                        .copyWith(
                                            color: Colors.white,
                                            fontSize:
                                                calculatedButtonFontSize)),
                              ),
                            )),
                      ]),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
