import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:getstream_flutter_example/core/di/injector.dart';
// import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/manage/auth/register/register_state.dart';
import 'package:getstream_flutter_example/features/presentation/manage/fetch_users/fetch_users_cubit.dart';
import 'package:getstream_flutter_example/features/presentation/view/home/layout.dart';
import 'package:stream_chat/src/client/client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  String userType = 'Student';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocConsumer<RegisterCubit, RegisterState>(
              listener: (context, state) {
                if (state is RegisterSuccessState) {
                  // After successful registration, fetch users based on role
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
              builder: (context, state) => SingleChildScrollView(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      const Center(child: Icon(Icons.people_sharp, size: 80)),
                      Center(
                          child: Text("GetStream.io Example",
                              style:
                                  Theme.of(context).textTheme.headlineLarge?.copyWith(color: CupertinoColors.black))),
                      const SizedBox(height: 60),
                      Text("Register",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: CupertinoColors.black)),
                      const SizedBox(height: 30),
                      TextFormField(
                        style: const TextStyle(color: CupertinoColors.black),
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: "Name",
                            labelStyle: TextStyle(color: CupertinoColors.black),
                            border: OutlineInputBorder(borderSide: BorderSide(color: CupertinoColors.black))),
                        validator: (value) => value!.isEmpty ? "Name is required" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: CupertinoColors.black),
                        decoration: const InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(color: CupertinoColors.black),
                            border: OutlineInputBorder(borderSide: BorderSide(color: CupertinoColors.black))),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.isEmpty) return "Email is required";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "Enter a valid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: userType,
                        style: const TextStyle(color: CupertinoColors.black),
                        focusColor: CupertinoColors.black,
                        decoration: const InputDecoration(labelText: "User Type"),
                        onChanged: (value) {
                          setState(() {
                            userType = value!;
                          });
                        },
                        items: ['Teacher', 'Student'].map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        validator: (value) => value == null ? "User type is required" : null,
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: state is RegisterLoadingState
                            ? const Center(child: CircularProgressIndicator())
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  height: 45,
                                  width: double.infinity,
                                  color: Colors.deepPurple,
                                  child: ElevatedButton(
                                    style:
                                        const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.deepPurple)),
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        final name = nameController.text.trim();
                                        final email = emailController.text.trim();
                                        const password = "Hello2024#";
                                        context.read<RegisterCubit>().registerUser(name, email, password, userType);
                                        emailController.clear();
                                        nameController.clear();
                                      }
                                    },
                                    child: const Text("Register",
                                        style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
