import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';

import '../../../core/utils/consts/functions.dart';
import '../manage/fetch_users/fetch_users_cubit.dart';
import '../view/home/layout.dart';

class SignupFormWidget extends StatefulWidget {
  const SignupFormWidget({super.key});

  @override
  State<SignupFormWidget> createState() => _SignupFormWidgetState();
}

class _SignupFormWidgetState extends State<SignupFormWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String userType = 'Student';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: BlocConsumer<RegisterCubit, RegisterState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Register in the server",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 22,
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.deepPurple,
                        decorationStyle: TextDecorationStyle.solid,
                        decorationThickness: 1)),
                const SizedBox(height: 20),
                TextFormField(
                  style: const TextStyle(color: CupertinoColors.black),
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(color: CupertinoColors.black),
                      border: OutlineInputBorder(borderSide: BorderSide(color: CupertinoColors.black))),
                  validator: (value) => value!.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: userType,
                        style: const TextStyle(color: CupertinoColors.black),
                        focusColor: CupertinoColors.black,
                        decoration: const InputDecoration(labelText: "User Type", border: OutlineInputBorder()),
                        onChanged: (value) => setState(() => userType = value!),
                        items: ['Teacher', 'Student']
                            .map((String type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: state is RegisterLoadingState
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    backgroundColor: Colors.deepPurple
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      'Register',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      final name = nameController.text.trim();
                                      final email = "${generateEmail().toString()}@gmail.com";
                                      const password = "Hello2024#";
                                      context.read<RegisterCubit>().registerUser(name, email, password, userType);
                                      nameController.clear();
                                      print("?>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Email: $email");
                                    }
                                  },
                                )),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
        listener: (context, state) {
          if (state is RegisterSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Success signup!!"),
              backgroundColor: CupertinoColors.activeGreen,
            ));
            context.read<FetchUsersCubit>().fetchUsersBasedOnRole().then((_) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Layout(type: userType)));
            });
          } else if (state is RegisterFailedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: CupertinoColors.destructiveRed,
              ),
            );
          }
        },
      ),
    );
  }
}
