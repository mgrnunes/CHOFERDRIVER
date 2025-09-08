import 'package:flutter/material.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF19213D),
      body: const Center(
        child: Text(
          'Configurações do aplicativo',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
