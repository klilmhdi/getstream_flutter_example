part of 'fetch_users_cubit.dart';

@immutable
abstract class FetchUsersState {}

final class FetchUsersInitial extends FetchUsersState {}

class UserLoading extends FetchUsersState {}

class UserLoaded extends FetchUsersState {
  // final List<Map<String, dynamic>> users;
  final List<UserModel> users;

  UserLoaded(this.users);
}

class UserError extends FetchUsersState {
  final String error;

  UserError(this.error);
}
