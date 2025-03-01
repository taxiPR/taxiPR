import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateDriverScreen extends StatelessWidget {
  const CreateDriverScreen({super.key});

  Future<void> _createDriver() async {
    final url = Uri.parse('http://192.168.1.9:4000/create-driver');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Conductor de Prueba',
          'phone': '0987654321',
          'role': 'driver', // Asegúrate de incluir el rol
          'location': {
            'type': 'Point',
            'coordinates': [-97.4607, 20.5403], // Ejemplo de coordenadas
          },
          'vehicle': 'Toyota Corolla',
          'bankAccount': '1234567890123456',
          'bankName': 'BBVA',
        }),
      );

      if (response.statusCode == 201) {
        print('Conductor creado exitosamente');
      } else {
        print('Error al crear conductor: ${response.statusCode}');
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
        title: const Text('Crear Conductor'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _createDriver();
            Navigator.pop(context); // Regresar a la pantalla anterior
          },
          child: const Text('Crear Conductor'),
        ),
      ),
    );
  }
}