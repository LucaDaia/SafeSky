import 'package:flutter/material.dart';
import 'package:safe_sky/services//auth_service.dart';
import 'register_page.dart';
import 'map_activity.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String? error;

  @override
  void initState() {
    super.initState();
    _authService.user.listen((user) {
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/map');
      } else {
        // stay on login page or do nothing
      }
    });
  }


  void _login() async {
    var user = await _authService.signIn(_emailController.text, _passwordController.text);
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/map');
    } else {
      setState(() {
        error = "Login failed. Check your credentials.";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background
      appBar: AppBar(
        title: Center(
          child: Text("Login",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        backgroundColor: Colors.black87, // Dark app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
              },
              child: Text(
                "Don't have an account? Register",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
