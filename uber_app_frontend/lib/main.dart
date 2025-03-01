import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Para geolocalización
import 'package:http/http.dart' as http; // Para solicitudes HTTP
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes
import 'dart:io'; // Para manejar archivos

void main() {
  runApp(const UberApp());
}

class UberApp extends StatelessWidget {
  const UberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/create-user': (context) => const CreateUserScreen(),
        '/create-driver': (context) => const CreateDriverScreen(),
      },
    );
  }
}

// Pantalla principal
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Función para verificar y solicitar permisos de ubicación
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('Los permisos de ubicación fueron denegados permanentemente.');
      return;
    }
    print('Permisos de ubicación concedidos.');
  }

  // Función para determinar la posición del usuario
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación fueron denegados permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Función para enviar la ubicación al backend
  Future<Map<String, dynamic>?> _sendLocationToBackend(Position position) async {
    final url = Uri.parse('http://192.168.1.9:4000/assign-driver');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'coordinates': [position.longitude, position.latitude], // Coordenadas del cliente
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al asignar conductor: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al conectar con el backend: $e');
      return null;
    }
  }

  // Función para mostrar los datos del conductor en un diálogo
  void _showDriverDetails(BuildContext context, Map<String, dynamic> driverData) {
    String imageUrl = '';
    if (driverData['photo'] != null) {
      if (driverData['photo'].toString().startsWith('http')) {
        imageUrl = driverData['photo'];
      } else {
        imageUrl = 'http://192.168.1.9:4000/image/${driverData['photo']}';
      }
      print('URL de la imagen: $imageUrl');
    } else {
      print('No hay imagen disponible para este conductor.');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conductor Asignado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nombre: ${driverData['name'] ?? 'No disponible'}'),
              Text('Teléfono: ${driverData['phone'] ?? 'No disponible'}'),
              Text('Vehículo: ${driverData['vehicle'] ?? 'No disponible'}'),
              Text('Banco: ${driverData['bankName'] ?? 'No disponible'}'),
              Text('Cuenta Bancaria: ${driverData['bankAccount'] ?? 'No disponible'}'),
              const SizedBox(height: 10),
              if (driverData['photo'] != null)
                Image.network(
                  imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Imagen no disponible');
                  },
                )
              else
                const Text('Sin imagen'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uber App'),
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido a Uber',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Solicita un conductor cercano en minutos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _checkLocationPermission();
                  Position position = await _determinePosition();
                  print('Ubicación obtenida: Latitud: ${position.latitude}, Longitud: ${position.longitude}');
                  Map<String, dynamic>? driverData = await _sendLocationToBackend(position);
                  if (driverData != null) {
                    print('Datos del conductor recibidos: $driverData');
                    _showDriverDetails(context, driverData);
                  } else {
                    print('No se pudo asignar un conductor.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo asignar un conductor. Inténtalo más tarde.')),
                    );
                  }
                } catch (e) {
                  print('Error al obtener la ubicación o conectar con el backend: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ocurrió un error. Por favor, verifica tu conexión.')),
                  );
                }
              },
              icon: const Icon(Icons.directions_car, size: 30),
              label: const Text('Solicitar Conductor', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-driver');
              },
              icon: const Icon(Icons.person_add, size: 30),
              label: const Text('Crear Conductor', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-user');
              },
              icon: const Icon(Icons.person_add, size: 30),
              label: const Text('Crear Usuario', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla para crear usuario
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final url = Uri.parse('http://192.168.1.9:4000/create-user');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'role': 'user',
          'location': jsonEncode({
            'type': 'Point',
            'coordinates': [-97.4607, 20.5403], // Ejemplo de coordenadas
          }),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado exitosamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear usuario: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el backend: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createUser,
                child: const Text('Crear Usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla para crear conductor
class CreateDriverScreen extends StatefulWidget {
  const CreateDriverScreen({super.key});

  @override
  _CreateDriverScreenState createState() => _CreateDriverScreenState();
}

class _CreateDriverScreenState extends State<CreateDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  String? _photoPath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoPath = pickedFile.path;
      });
    }
  }

  Future<void> _createDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final url = Uri.parse('http://192.168.1.9:4000/create-driver');
    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['name'] = _nameController.text
        ..fields['phone'] = _phoneController.text
        ..fields['role'] = 'driver'
        ..fields['location'] = jsonEncode({
          "coordinates": [-97.460538, 20.540408] // Coordenadas de ejemplo
        })
        ..fields['vehicle'] = _vehicleController.text
        ..fields['bankAccount'] = _bankAccountController.text
        ..fields['bankName'] = _bankNameController.text;

      if (_photoPath != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _photoPath!));
      }

      final response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conductor creado exitosamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear conductor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el backend: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Conductor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el teléfono';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _vehicleController,
                decoration: const InputDecoration(labelText: 'Vehículo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el vehículo';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _bankAccountController,
                decoration: const InputDecoration(labelText: 'Cuenta Bancaria'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa la cuenta bancaria';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Banco'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el banco';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Seleccionar Imagen'),
              ),
              if (_photoPath != null)
                Image.file(File(_photoPath!), height: 100, width: 100, fit: BoxFit.cover),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createDriver,
                child: const Text('Crear Conductor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}