import 'package:firebase_auth/firebase_auth.dart';

const welfareAdminEmail = 'mustafa79996@gmail.com';

bool isWelfareAdmin(User? user) {
  if (user == null || user.email == null) return false;
  return user.email!.trim().toLowerCase() == welfareAdminEmail.toLowerCase();
}
