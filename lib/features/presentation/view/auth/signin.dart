import 'package:flutter/material.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/app_title_and_icon_widget.dart';
import 'package:getstream_flutter_example/features/presentation/widgets/signup_form_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [appIconAndTitleWidget(context), const SignupFormWidget()],
                  )
                : Container(
                    padding: const EdgeInsets.all(32.0),
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(child: appIconAndTitleWidget(context)),
                        const Expanded(child: SignupFormWidget())
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
