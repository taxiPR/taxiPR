const express = require('express');
const mongoose = require('mongoose');
const multer = require('multer');
const path = require('path'); // Para manejar rutas de archivos
const fs = require('fs'); // Para manejar archivos
require('dotenv').config(); // Cargar variables de entorno desde .env

const app = express();
const port = process.env.PORT || 4000; // Usar el puerto definido en .env o 4000 por defecto

// Configuración para servir archivos estáticos desde la carpeta 'public/image'
app.use('/image', express.static(path.join(__dirname, 'public', 'image')));

// Conexión a MongoDB usando la variable de entorno MONGO_URI
const mongoURI = process.env.MONGO_URI;
mongoose.connect(mongoURI)
  .then(() => console.log('Conectado a MongoDB'))
  .catch(err => {
    console.error('Error al conectar a MongoDB:', err);
    process.exit(1); // Detener la aplicación si no se puede conectar a MongoDB
  });

// Middleware para parsear JSON
app.use(express.json());

// Configuración de multer para almacenar imágenes en memoria
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Modelo de Usuario
const userSchema = new mongoose.Schema({
  name: String,
  phone: String,
  role: String,
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: true
    },
    coordinates: {
      type: [Number],
      required: true
    }
  },
  vehicle: String,
  bankAccount: String,
  bankName: String,
  photo: String // Guardaremos el nombre del archivo de la imagen aquí (opcional para usuarios)
});
userSchema.index({ location: '2dsphere' }); // Índice geoespacial
const User = mongoose.model('User', userSchema);

// Ruta raíz (para verificar que el servidor está funcionando)
app.get('/', (req, res) => {
  res.send('¡Hola, mundo! Backend funcionando.');
});

// Ruta para crear un conductor con imagen
app.post('/create-driver', upload.single('photo'), async (req, res) => {
  try {
    const { name, phone, role, location, vehicle, bankAccount, bankName } = req.body;

    // Validar que location sea un objeto JSON válido
    let parsedLocation;
    try {
      const decodedLocation = decodeURIComponent(location); // Decodificar caracteres escapados
      parsedLocation = JSON.parse(decodedLocation);
    } catch (error) {
      return res.status(400).send('El campo "location" debe ser un objeto JSON válido con coordenadas');
    }

    if (!parsedLocation || typeof parsedLocation !== 'object' || !Array.isArray(parsedLocation.coordinates)) {
      return res.status(400).send('El campo "location" debe ser un objeto JSON válido con coordenadas');
    }

    // Validar que se haya enviado una imagen
    if (!req.file) {
      return res.status(400).send('No se proporcionó ninguna imagen');
    }

    // Guardar la imagen en MongoDB como un nombre único
    const filename = Date.now() + path.extname(req.file.originalname); // Nombre único para la imagen

    // Crear el conductor en la base de datos
    const user = new User({
      name,
      phone,
      role,
      location: {
        type: 'Point',
        coordinates: parsedLocation.coordinates
      },
      vehicle,
      bankAccount,
      bankName,
      photo: filename // Guardar el nombre del archivo en la base de datos
    });

    await user.save();

    // Guardar la imagen en la carpeta 'public/image'
    const filePath = path.join(__dirname, 'public', 'image', filename);
    fs.writeFileSync(filePath, req.file.buffer);

    res.status(201).send('Conductor creado exitosamente');
  } catch (error) {
    console.error('Error en /create-driver:', error);
    res.status(500).send('Error al crear el conductor');
  }
});

// Ruta para crear un usuario sin imagen
app.post('/create-user', async (req, res) => {
  try {
    const { name, phone, role, location } = req.body;

    // Validar que location sea un objeto JSON válido
    let parsedLocation;
    try {
      const decodedLocation = decodeURIComponent(location); // Decodificar caracteres escapados
      parsedLocation = JSON.parse(decodedLocation);
    } catch (error) {
      return res.status(400).send('El campo "location" debe ser un objeto JSON válido con coordenadas');
    }

    if (!parsedLocation || typeof parsedLocation !== 'object' || !Array.isArray(parsedLocation.coordinates)) {
      return res.status(400).send('El campo "location" debe ser un objeto JSON válido con coordenadas');
    }

    // Crear el usuario en la base de datos
    const user = new User({
      name,
      phone,
      role,
      location: {
        type: 'Point',
        coordinates: parsedLocation.coordinates
      }
    });

    await user.save();

    res.status(201).send('Usuario creado exitosamente');
  } catch (error) {
    console.error('Error en /create-user:', error);
    res.status(500).send('Error al crear el usuario');
  }
});

// Endpoint para asignar un conductor cercano
app.post('/assign-driver', async (req, res) => {
  try {
    const { coordinates } = req.body;

    if (!coordinates || !Array.isArray(coordinates) || coordinates.length !== 2) {
      return res.status(400).send('Coordenadas inválidas');
    }

    const nearbyDrivers = await User.find({
      role: 'driver',
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: coordinates
          },
          $maxDistance: 5000 // Máximo 5 km de distancia
        }
      }
    }).limit(1);

    if (nearbyDrivers.length === 0) {
      return res.status(404).send('No hay conductores disponibles cerca');
    }

    const assignedDriver = nearbyDrivers[0];
    res.json({
      name: assignedDriver.name,
      phone: assignedDriver.phone,
      vehicle: assignedDriver.vehicle,
      bankAccount: assignedDriver.bankAccount,
      bankName: assignedDriver.bankName,
      photo: assignedDriver.photo ? `${process.env.BACKEND_URL}/image/${assignedDriver.photo}` : null,
      location: assignedDriver.location.coordinates
    });
  } catch (error) {
    console.error(error);
    res.status(500).send('Error al asignar conductor');
  }
});

// Ruta para obtener la imagen de un conductor
app.get('/image/:filename', (req, res) => {
  const file = path.join(__dirname, 'public', 'image', req.params.filename);
  fs.access(file, fs.constants.F_OK, (err) => {
    if (err) {
      return res.status(404).send('Archivo no encontrado');
    }
    res.sendFile(file);
  });
});

// Iniciar el servidor
const host = '0.0.0.0'; // Permite conexiones desde cualquier dirección IP
app.listen(port, host, () => {
  console.log(`Servidor escuchando en http://${host}:${port}`);
});