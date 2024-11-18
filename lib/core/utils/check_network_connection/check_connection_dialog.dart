// import 'package:flutter/material.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart';
//
// import '../../app/app_consumers.dart';
//
// final Connectivity _connectivity = Connectivity();
//
// Future<void> checkNetworkAndInitializeApp(context) async {
//   final connectivityResult = await _connectivity.checkConnectivity();
//
//   if (connectivityResult == ConnectivityResult.none) {
//     showNetworkErrorDialog(context);
//   } else {
//     appLoader = AppConsumers().initializeServices(context);
//   }
// }
//
// void showNetworkErrorDialog(context) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text("No Internet Connection"),
//         content: const Text("Please check your network and try again."),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               final connectivityResult =
//               await _connectivity.checkConnectivity();
//               if (connectivityResult != ConnectivityResult.none) {
//                 Navigator.of(context).pop();
//                 checkNetworkAndInitializeApp();
//               }
//             },
//             child: const Text("Retry"),
//           ),
//         ],
//       );
//     },
//   );
// }