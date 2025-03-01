import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateUserScreen extends StatelessWidget {
  const CreateUserScreen({super.key});

  Future<void> _createUser() async {
    final url = Uri.parse('https://taxipr.onrender.com/create-user');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Usuario de Prueba',
          'phone': '1234567890',
          'role': 'user', // Rol del usuario
          'location': {
            'type': 'Point',
            'coordinates': [-97.4607, 20.5403], // Ejemplo de coordenadas
          },
        }),
      );

      if (response.statusCode == 201) {
        print('Usuario creado exitosamente');
      } else {
        print('Error al crear usuario: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
      }
    } catch (e) {
      print('Error al conectar con el backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Usuario'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _createUser();
            Navigator.pop(context); // Regresar a la pantalla anterior
          },
          child: const Text('Crear Usuario'),
        ),
      ),
    );
  }
}