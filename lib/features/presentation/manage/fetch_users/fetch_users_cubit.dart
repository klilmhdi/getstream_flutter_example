// import 'package:bloc/bloc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:getstream_flutter_example/features/data/models/user_model.dart';
// import 'package:getstream_flutter_example/features/data/services/firebase_services.dart';
// import 'package:meta/meta.dart';
//
// part 'fetch_users_state.dart';
//
// class FetchUsersCubit extends Cubit<FetchUsersState> {
//   FetchUsersCubit() : super(FetchUsersInitial());
//
//   // final FirebaseServices firebase = FirebaseServices();
//
//   // void fetchUsers() async {
//   //   emit(UserLoading());
//   //   try {
//   //     final currentUser = firebase.currentId;
//   //     print("?>>>>>>>>>>>>>>>>>>currentUser: $currentUser");
//   //
//   //     QuerySnapshot usersSnapshot = await firebase.firestore
//   //         .collection('users')
//   //         .where('uid', isNotEqualTo: currentUser) // Exclude current user
//   //         .get();
//   //
//   //     List<Map<String, dynamic>> users = usersSnapshot.docs.map((doc) {
//   //       return doc.data() as Map<String, dynamic>;
//   //     }).toList();
//   //
//   //     emit(UserLoaded(users));
//   //   } catch (e, stackTrace) {
//   //     print("?>>>>>>>>>>>>>>>>>>error: $e");
//   //     print("?>>>>>>>>>>>>>>>>>>stackTrace: $stackTrace");
//   //     emit(UserError(e.toString()));
//   //   }
//   // }
//   // Fetch the current user's details
//
//   var firestore = FirebaseServices().firestore;
//   var auth = FirebaseServices().auth;
//   Future<void> fetchCurrentUser() async {
//     emit(UserLoading());
//
//     try {
//       User? user = auth.currentUser;
//
//       if (user == null) {
//         emit(UserError("No authenticated user found."));
//         return;
//       }
//
//       DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
//
//       if (!userDoc.exists) {
//         emit(UserError("User document does not exist."));
//         return;
//       }
//
//       UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);
//
//       emit(UserLoaded(currentUser as List<Map<String, dynamic>>));
//     } catch (e) {
//       emit(UserError("Failed to fetch user: ${e.toString()}"));
//     }
//   }
//
//   // Fetch users based on the current user's role
//   Future<void> fetchUsersBasedOnRole() async {
//     emit(UserLoading());
//
//     try {
//       User? user = auth.currentUser;
//
//       if (user == null) {
//         emit(UserError("No authenticated user found."));
//         return;
//       }
//
//       DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
//
//       if (!userDoc.exists) {
//         emit(UserError("User document does not exist."));
//         return;
//       }
//
//       UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);
//
//       String targetRole = currentUser.role == "Teacher" ? "Student" : "Teacher";
//
//       QuerySnapshot targetUsersSnapshot = await firestore
//           .collection('users')
//           .where('role', isEqualTo: targetRole)
//           .get();
//
//       List<UserModel> targetUsers = targetUsersSnapshot.docs.map((doc) {
//         return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
//       }).toList();
//
//       emit(UserLoaded(targetUsers.cast<Map<String, dynamic>>()));
//     } catch (e, s) {
//       print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
//       print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
//       emit(UserError("Failed to fetch users: ${e.toString()}"));
//     }
//   }
// }



// fetch_users_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:getstream_flutter_example/features/data/models/user_model.dart';
import 'package:meta/meta.dart';

part 'fetch_users_state.dart';

class FetchUsersCubit extends Cubit<FetchUsersState> {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FetchUsersCubit({required this.firestore, required this.auth}) : super(FetchUsersInitial());

  // Fetch the current user's details
  Future<void> fetchCurrentUser() async {
    emit(UserLoading());

    try {
      User? user = auth.currentUser;

      if (user == null) {
        emit(UserError("No authenticated user found."));
        return;
      }

      DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        emit(UserError("User document does not exist."));
        return;
      }

      UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);
      String displayName = user.displayName ?? currentUser.name;

      emit(UserLoaded([currentUser.copyWith(name: displayName)]));
    } on FirebaseException catch (e, s) {
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
      if (e.code == 'permission-denied') {
        emit(UserError("Permission denied: ${e.message}"));
      } else {
        emit(UserError("Failed to fetch user: ${e.message}"));
      }
    } catch (e, s) {
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
      emit(UserError("Failed to fetch user: ${e.toString()}"));
    }
  }

  // Fetch users based on the current user's role
  Future<void> fetchUsersBasedOnRole() async {
    emit(UserLoading());

    try {
      User? user = auth.currentUser;

      if (user == null) {
        emit(UserError("No authenticated user found."));
        return;
      }

      // Fetch the current user's role (from the correct subcollection)
      DocumentSnapshot userDocTeacher = await firestore.collection('users').doc('teachers').collection(user.uid).doc(user.uid).get();
      DocumentSnapshot userDocStudent = await firestore.collection('users').doc('students').collection(user.uid).doc(user.uid).get();

      DocumentSnapshot userDoc = userDocTeacher.exists ? userDocTeacher : userDocStudent;

      if (!userDoc.exists) {
        emit(UserError("User document does not exist."));
        return;
      }

      UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);

      // Determine which role to target (opposite of current user's role)
      String targetRole = currentUser.role == "Teacher" ? "students" : "teachers";

      // Fetch users from the corresponding subcollection
      QuerySnapshot targetUsersSnapshot = await firestore
          .collection('users')
          .doc(targetRole)
          .collection(targetRole)
          .get();

      List<UserModel> targetUsers = targetUsersSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      emit(UserLoaded(targetUsers));
    } on FirebaseException catch (e, s) {
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
      if (e.code == 'permission-denied') {
        emit(UserError("Permission denied: ${e.message}"));
      } else {
        emit(UserError("Failed to fetch users: ${e.message}"));
      }
    } catch (e, s) {
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
      print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
      emit(UserError("Failed to fetch users: ${e.toString()}"));
    }
  }
  // Future<void> fetchUsersBasedOnRole() async {
  //   emit(UserLoading());
  //
  //   try {
  //     User? user = auth.currentUser;
  //
  //     if (user == null) {
  //       emit(UserError("No authenticated user found."));
  //       return;
  //     }
  //
  //     // Fetch the current user's document (to know their role)
  //     DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
  //
  //     if (!userDoc.exists) {
  //       emit(UserError("User document does not exist."));
  //       return;
  //     }
  //
  //     UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);
  //
  //     // Determine which role to target (opposite of current user's role)
  //     String targetRole = currentUser.role == "Teacher" ? "students" : "teachers";
  //
  //     // Fetch users from the corresponding subcollection
  //     QuerySnapshot targetUsersSnapshot = await firestore
  //         .collection('users')
  //         .doc(targetRole)
  //         .collection(targetRole)
  //         .get();
  //
  //     List<UserModel> targetUsers = targetUsersSnapshot.docs.map((doc) {
  //       return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  //     }).toList();
  //
  //     emit(UserLoaded(targetUsers));
  //   } on FirebaseException catch (e, s) {
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
  //     if (e.code == 'permission-denied') {
  //       emit(UserError("Permission denied: ${e.message}"));
  //     } else {
  //       emit(UserError("Failed to fetch users: ${e.message}"));
  //     }
  //   } catch (e, s) {
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
  //     emit(UserError("Failed to fetch users: ${e.toString()}"));
  //   }
  // }
  // Future<void> fetchUsersBasedOnRole() async {
  //   emit(UserLoading());
  //
  //   try {
  //     User? user = auth.currentUser;
  //
  //     if (user == null) {
  //       emit(UserError("No authenticated user found."));
  //       return;
  //     }
  //
  //     DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
  //
  //     if (!userDoc.exists) {
  //       emit(UserError("User document does not exist."));
  //       return;
  //     }
  //
  //     UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);
  //
  //     String targetRole = currentUser.role == "Teacher" ? "Student" : "Teacher";
  //
  //     QuerySnapshot targetUsersSnapshot = await firestore
  //         .collection('users')
  //         .where('role', isEqualTo: targetRole)
  //         .get();
  //
  //     List<UserModel> targetUsers = targetUsersSnapshot.docs.map((doc) {
  //       return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  //     }).toList();
  //
  //     emit(UserLoaded(targetUsers));
  //   } on FirebaseException catch (e, s) {
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
  //     if (e.code == 'permission-denied') {
  //       emit(UserError("Permission denied: ${e.message}"));
  //     } else {
  //       emit(UserError("Failed to fetch users: ${e.message}"));
  //     }
  //   } catch (e, s) {
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>Error: ${e.toString()}");
  //     print("@>>>>>>>>>>>>>>>>>>>>>>>>>>>StackTrace: ${s.toString()}");
  //     emit(UserError("Failed to fetch users: ${e.toString()}"));
  //   }
  // }
}
