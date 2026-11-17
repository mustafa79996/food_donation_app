import 'package:firebase_auth/firebase_auth.dart';

const welfareAdminEmail = 'mustafa79996@gmail.com';
const List<String> welfareAdminEmails = [
  'mustafa79996@gmail.com',
  'admin@foodlink.org',
];

bool isWelfareAdmin(User? user) {
  if (user == null || user.email == null) return false;
  final email = user.email!.trim().toLowerCase();
  return welfareAdminEmails.any((admin) => admin.toLowerCase() == email);
}
