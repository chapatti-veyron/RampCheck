import 'package:flutter/material.dart';
import '../services/internal_db.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onOk;

  const LoginScreen({super.key, required this.onOk});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController u = TextEditingController();
  final TextEditingController p = TextEditingController();

  bool busy = false;
  String msg = '';

  @override
  void dispose() {
    u.dispose();
    p.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    setState(() {
      busy = true;
      msg = '';
    });

    String user = u.text.trim();
    String pass = p.text;

    if (user.isEmpty || pass.isEmpty) {
      setState(() {
        busy = false;
        msg = 'Enter username and password';
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
      msg = 'Login failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login')
      ),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Maintenance Tool',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    )
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: u,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder()
                    )
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: p,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder()
                    ),
                    onSubmitted: (_) => doLogin()
                  ),
                  const SizedBox(height: 12),
                  if (msg.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(msg, style: const TextStyle(color: Colors.red))
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : doLogin,
                      child: Text(busy ? 'Checking...' : 'Enter')
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
