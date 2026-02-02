import 'package:flutter/material.dart';
import '../services/internal_db.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onOk;

  const LoginScreen({super.key, required this.onOk});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool busy = false;
  String errorMsg = '';

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    setState(() {
      busy = true;
      errorMsg = '';
    });

    String user = username.text.trim();
    String pass = password.text;

    if (user.isEmpty || pass.isEmpty) {
      setState(() {
        busy = false;
        errorMsg = 'Enter username and password';
      });
      return;
    }

    bool ok = await DatabaseHelper.authenticateUser(user, pass);

    if (ok) {
      widget.onOk();
      return;
    }

    setState(() {
      busy = false;
      errorMsg = 'Login failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'RampCheck',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder()
                    ),
                    onSubmitted: (_) => doLogin()
                  ),
                  const SizedBox(height: 12),
                  if (errorMsg.isNotEmpty)
                    Text(errorMsg, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : doLogin,
                      child: const Text('Login')
                    )
                  )
                ]
              )
            )
          )
        )
      )
    );
  }
}