const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true },
  role: { type: String, required: true },
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
  vehicle: { type: String, required: false },
  bankAccount: { type: String, required: false },
  bankName: { type: String, required: false },
  photo: { type: String, required: false } // Nombre del archivo en GridFS
});

// Índice geoespacial para la ubicación
userSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('User', userSchema);