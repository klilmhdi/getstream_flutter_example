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

  // Fetch the current user details
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

  // Fetch the user's details depend on rules
  Future<void> fetchUsersBasedOnRole() async {
    emit(UserLoading());
    print("Started fetching users based on role.");

    try {
      User? user = auth.currentUser;
      if (user == null) {
        print("No authenticated user found.");
        emit(UserError("No authenticated user found."));
        return;
      }

      // Fetch current user's document
      DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print("User document does not exist for uid: ${user.uid}");
        emit(UserError("User document does not exist."));
        return;
      }

      // Identify the role based on user data
      UserModel currentUser = UserModel.fromMap(user.uid, userDoc.data() as Map<String, dynamic>);
      String targetRole = currentUser.role == "Teacher" ? "Student" : "Teacher";
      print("Current user role: ${currentUser.role}, Target role: $targetRole");

      // Fetch target users
      QuerySnapshot targetUsersSnapshot =
          await firestore.collection('users').where('role', isEqualTo: targetRole).get();

      if (targetUsersSnapshot.docs.isEmpty) {
        print("No users found with role: $targetRole.");
        emit(UserError("No users found for the target role."));
        return;
      }

      // Convert snapshot to list of UserModel
      List<UserModel> targetUsers = targetUsersSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      print("Users found: ${targetUsers.length}");
      emit(UserLoaded(targetUsers));
    } on FirebaseException catch (e) {
      print("FirebaseException error: ${e.message}");
      emit(UserError("Failed to fetch users: ${e.message}"));
    } catch (e) {
      print("General error: ${e.toString()}");
      emit(UserError("An error occurred while fetching users."));
    }
  }
}
