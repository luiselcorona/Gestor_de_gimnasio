import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymy/presentation/gym_classes/gym_classes_screen.dart';
import 'package:gymy/basedatos_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void login() async {
    final username = usernameController.text;
    final password = usernameController.text;

    final user = await _dbHelper.getUser(username);
    if (user != null && user['password'] == password) {
      Get.to(GymClassesScreen());
    } else {
      _showErrorDialog('Invalid username or password');
    }
  }

  Future<void> register() async {
    final username = usernameController.text;
    final password = usernameController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      final existingUser = await _dbHelper.getUser(username);
      if (existingUser != null) {
        _showErrorDialog('Username already exists');
      } else {
        await _dbHelper.insertUser(username, password);
        _showSuccessDialog('User registered successfully');
        updateUserList(); // Ensure the user list updates in real-time
      }
    } else {
      _showErrorDialog('Please enter a valid username and password');
    }
  }

  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void updateUserList() {}
}
