import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymy/presentation/login/login_controller.dart';
import 'package:gymy/presentation/register/register_screen.dart';
import 'package:gymy/basedatos_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymy/main.dart';

class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = Get.put(LoginController());
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _obscureText = true;
  bool adminLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAdminLoggedIn();
  }

  Future<void> _checkAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminLoggedIn = prefs.getBool('adminLoggedIn') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/cbum.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _dbHelper.getUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text('No hay usuario registrado');
                        } else {
                          return DropdownButton<String>(
                            hint: Text('Seleccionar usuario'),
                            onChanged: (String? newValue) {
                              _controller.usernameController.text = newValue!;
                            },
                            items: snapshot.data!.map<DropdownMenuItem<String>>((Map<String, dynamic> user) {
                              return DropdownMenuItem<String>(
                                value: user['username'],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(user['username']),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () async {
                                        await _dbHelper.deleteUser(user['username']);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _controller.usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _controller.passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_controller.usernameController.text == 'luiselcorona' &&
                                _controller.passwordController.text == 'Luisangel_01.100') {
                              // Special privileges for admin user
                              adminLoggedIn = true;
                              _controller.login();
                            } else {
                              _controller.login();
                            }
                          },
                          child: Text('Iniciar sesión', style: TextStyle(color: Colors.black87)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Get.to(
                              RegisterScreen(),
                              transition: Transition.fadeIn, // Add transition effect
                              duration: Duration(milliseconds: 500), // Duration of the transition
                            );
                            setState(() {});
                          },
                          child: Text('Registrar', style: TextStyle(color: Colors.black87)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
