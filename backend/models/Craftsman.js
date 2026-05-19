const mongoose = require('mongoose');

const CraftsmanSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  phone: {
    type: String,
    required: true
  },
  category: {
    type: String,
    required: true,
    trim: true
  },
  price: {
    type: Number,
    required: true
  },
  experience: {
    type: Number,
    required: true
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  rating: {
    type: Number,
    default: 5.0
  },
  password: {
    type: String,
    required: true
  },
  userType: {
    type: String,
    default: 'craftsman'
  },
  photoUrl: {
    type: String,
    default: null
  },
  address: {
    type: String,
    default: ''
  },
  city: {
    type: String,
    default: ''
  },
  bio: {
    type: String,
    default: ''
  },
  services: {
    type: [String],
    default: []
  },
  completedJobs: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Craftsman', CraftsmanSchema);
