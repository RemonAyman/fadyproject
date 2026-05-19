const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  serviceType: {
    type: String,
    required: true
  },
  location: {
    type: String,
    required: true
  },
  expectedPrice: {
    type: Number,
    required: true
  },
  appointmentDate: {
    type: Date,
    required: true
  },
  appointmentTime: {
    type: String,
    required: true
  },
  craftsmanId: {
    type: String,
    required: true
  },
  craftsmanName: {
    type: String,
    required: true
  },
  craftsmanCategory: {
    type: String,
    required: true
  },
  customerId: {
    type: String,
    required: true
  },
  customerName: {
    type: String,
    required: true
  },
  customerPhone: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['new', 'confirmed', 'completed', 'cancelled'],
    default: 'new'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Booking', BookingSchema);
