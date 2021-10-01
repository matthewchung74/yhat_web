import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yhat_app/controller/providers.dart';
import 'package:yhat_app/helpers/ui.dart';
import 'package:yhat_app/models/token.dart';
import 'package:yhat_app/models/user.dart';
import 'package:yhat_app/page/model_run_page.dart';
import 'package:yhat_app/widgets/my_app_bar.dart';
import 'package:yhat_app/widgets/snack_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../main.dart';

final signinController = StateNotifierProvider.autoDispose
    .family<SigninNotifier, AsyncValue<User>?, String?>((ref, code) {
  return SigninNotifier(read: ref.read, code: code);
});

class SigninNotifier extends StateNotifier<AsyncValue<User>?> {
  SigninNotifier({required this.read, required this.code}) : super(null) {
    if (code != null) {
      sendGithubAuthCode(code: code!);
    }
  }

  final Reader read;
  final String? code;

  void sendAuthEmail({required String email}) async {
    state = AsyncLoading();
    try {
      bool sent = await read(apiProvider).signup(email: email);
      if (sent) {
        User user = read(meController.notifier).state.clone();
        user.email = email;
        read(meController.notifier).state = user;
        state = AsyncData(user);
      }
    } catch (e) {
      state = AsyncError(e);
    }
  }

  void sendGithubAuthCode({required String code}) async {
    state = AsyncLoading();
    try {
      final Token token = await read(apiProvider).createGithubToken(code: code);

      // set token
      User user = read(meController.notifier).state.clone();
      user.token = token;
      read(meController.notifier).state = user;
      user = await read(apiProvider).fetchMe();
      user.token = token;
      read(meController.notifier).state = user;
      read(meController.notifier).persist();
// todo need to redirect here
      state = AsyncData(user);
    } catch (e) {
      state = AsyncError(e);
    }
  }
}

class SignInPage extends ConsumerWidget {
  final String? code;
  final MaterialPage? referrer;
  final TextEditingController emailController = TextEditingController();

  SignInPage({Key? key, this.code, this.referrer}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(signinController(code));
    final notifier = ref.read(signinController(code).notifier);

    void emailSignIn({required String email}) {
      notifier.sendAuthEmail(email: email);
    }

    void githubSignIn() {
      String launchUrl = env['GITHUB_AUTH_URL']!;

      if (referrer != null) {
        if (referrer!.child is ModelRunPage) {
          final runModelPage = referrer!.child as ModelRunPage;
          final newUrl = "${Uri.base.origin}/run_model/${runModelPage.modelId}";
          final provider = ref.read(referrerController.notifier);
          provider.url = newUrl;
          provider.persist();
        }
      }
      launchURLBrowser(url: launchUrl, target: '_self');
    }

    return Scaffold(
        appBar: myAppBar(context: context, ref: ref, showRightAction: false),
        body: (controller != null)
            ? controller.when(
                data: (data) {
                  if (data.type == UserType.NotEmailVerified) {
                    return SignInWidget(
                      emailSignIn: emailSignIn,
                      githubSignIn: githubSignIn,
                      message: "Please Check your Email",
                      snackBarStatus: SnackBarStatus.Success,
                      emailController: emailController,
                    );
                  } else if (data.type == UserType.EmailVerified ||
                      data.type == UserType.GithubVerified) {
                    String? url = ref.read(referrerController.notifier).url;
                    if (url != null) {
                      launchURLBrowser(url: url, target: "_self");
                    } else {
                      Future.microtask(() {
                        ref.read(navigationStackProvider).popToRoot();
                      });
                    }
                    return Container();
                  }
                },
                loading: () {
                  return Stack(
                    children: [
                      LinearProgressIndicator(),
                      SignInWidget(
                        emailSignIn: emailSignIn,
                        githubSignIn: githubSignIn,
                        enabled: false,
                        emailController: emailController,
                      ),
                    ],
                  );
                },
                error: (error, st) {
                  return SignInWidget(
                    emailSignIn: emailSignIn,
                    githubSignIn: githubSignIn,
                    message: error.toString(),
                    snackBarStatus: SnackBarStatus.Alert,
                    emailController: emailController,
                  );
                },
              )
            : SignInWidget(
                emailSignIn: emailSignIn,
                githubSignIn: githubSignIn,
                emailController: emailController,
              ));
  }
}

bool _isEmail(String? string) {
  if (string == null || string.isEmpty) {
    return false;
  }

  const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(string)) {
    return false;
  }
  return true;
}

class SignInWidget extends StatefulWidget {
  const SignInWidget(
      {required this.emailSignIn,
      required this.githubSignIn,
      this.enabled = true,
      this.message,
      this.snackBarStatus,
      required this.emailController});
  final Function({required String email}) emailSignIn;
  final Function() githubSignIn;
  final bool enabled;
  final String? message;
  final SnackBarStatus? snackBarStatus;
  final TextEditingController emailController;

  @override
  State<StatefulWidget> createState() {
    return _SignInWidgetState(
        emailSignIn: emailSignIn,
        githubSignIn: githubSignIn,
        enabled: enabled,
        message: message,
        snackBarStatus: snackBarStatus,
        emailController: emailController);
  }
}

class _SignInWidgetState extends State<SignInWidget> {
  _SignInWidgetState({
    required this.emailSignIn,
    required this.githubSignIn,
    required this.enabled,
    this.message,
    this.snackBarStatus,
    required this.emailController,
    // this.referrer});
  });

  final Function({required String email}) emailSignIn;
  final Function() githubSignIn;
  final bool enabled;
  String? _email;
  final String? message;
  final SnackBarStatus? snackBarStatus;
  final TextEditingController emailController;
  // final String? referrer;

  @override
  void initState() {
    if (message != null && snackBarStatus != null) {
      showSnackBar(
          context: context, message: message!, status: snackBarStatus!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = _isEmail(_email) && enabled == true
        ? () {
            emailSignIn(email: _email!);
          }
        : () {};
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              TextField(
                enabled: false,
                controller: emailController,
                decoration: InputDecoration(
                    labelText: "EMAIL (email signin not available yet)",
                    errorText: null),
                onChanged: (email) {
                  setState(() {
                    _email = email;
                  });
                },
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: onPressed,
                  style: _isEmail(_email)
                      ? Theme.of(context).elevatedButtonTheme.style
                      : ElevatedButton.styleFrom(primary: Colors.grey.shade400),
                  child: SizedBox(
                    width: 300,
                    height: 40,
                    child: Center(
                      child: Text("Sign In",
                          style: Theme.of(context)
                              .textTheme
                              .headline5!
                              .copyWith(color: Colors.white)),
                    ),
                  )),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          ElevatedButton(
              onPressed: () {
                // githubSignIn(referrer);

                githubSignIn();
              },
              // onPressed: () {
              // String launchUrl =
              //     'https://github.com/login/oauth/authorize?client_id=83c02f424e713d273c5b&scope=user%20repo';
              // if (referrer != null) {
              //   launchUrl = '$launchUrl&redirect_uri=$referrer';
              // }
              // launchURLBrowser(url: launchUrl, target: '_self');
              // },
              style: ElevatedButton.styleFrom(primary: Colors.white),
              child: SizedBox(
                height: 40,
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Sign In With Github",
                        style: Theme.of(context)
                            .textTheme
                            .headline5!
                            .copyWith(color: Colors.black)),
                    Image(
                      image: AssetImage('image/github.png'),
                      width: 30,
                      height: 30,
                    ),
                  ],
                ),
              )),
          SizedBox(
            height: 4,
          ),
          Text(
            '(Required for model Upload)',
            style: Theme.of(context)
                .textTheme
                .bodyText2!
                .copyWith(color: Colors.grey.shade500),
          )
        ],
      ),
    );
  }
}
