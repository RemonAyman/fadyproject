import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Smart detection for base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  // --- Helper Methods ---

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth APIs ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token'] ?? '');
        await prefs.setString('userId', responseData['userId'] ?? '');
        await prefs.setString('userType', responseData['userType'] ?? '');
        await prefs.setString('name', responseData['name'] ?? '');
        await prefs.setString('email', responseData['email'] ?? '');
        await prefs.setBool('isLoggedIn', true);
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': responseData['error'] ?? 'فشل تسجيل الدخول'};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم، يرجى المحاولة لاحقاً'};
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String address,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'city': city,
          'address': address,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token'] ?? '');
        await prefs.setString('userId', responseData['userId'] ?? '');
        await prefs.setString('userType', responseData['userType'] ?? '');
        await prefs.setString('name', responseData['name'] ?? '');
        await prefs.setString('email', responseData['email'] ?? '');
        await prefs.setBool('isLoggedIn', true);
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': responseData['error'] ?? 'فشل التسجيل'};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> registerCraftsman({
    required String name,
    required String email,
    required String phone,
    required String category,
    required double price,
    required int experience,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register-craftsman'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'category': category,
          'price': price,
          'experience': experience,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token'] ?? '');
        await prefs.setString('userId', responseData['userId'] ?? '');
        await prefs.setString('userType', responseData['userType'] ?? '');
        await prefs.setString('name', responseData['name'] ?? '');
        await prefs.setString('email', responseData['email'] ?? '');
        await prefs.setBool('isLoggedIn', true);
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': responseData['error'] ?? 'فشل تسجيل الحرفي'};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userType');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  // --- Craftsmen Directory ---

  Future<List<dynamic>> getAllCraftsmen({
    String? category,
    String? city,
    double? minRating,
    double? maxPrice,
    bool? isAvailable,
    String? search,
    String? sortBy,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;

      final uri = Uri.parse('$baseUrl/api/craftsmen').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading craftsmen: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCraftsmanDetails(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/craftsmen/$id'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading craftsman details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> updateCraftsmanProfile(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/craftsmen/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Also update local cached name if name changed
        if (data.containsKey('name')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', data['name']);
        }
        return {'success': true, 'data': resBody};
      }
      return {'success': false, 'error': resBody['error'] ?? 'فشل تعديل البيانات'};
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  // --- User Profile APIs ---

  Future<Map<String, dynamic>?> getUserProfile(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/users/$id'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> updateUserProfile(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data.containsKey('name')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', data['name']);
        }
        return {'success': true, 'data': resBody};
      }
      return {'success': false, 'error': resBody['error'] ?? 'فشل تعديل البيانات'};
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  // --- Bookings APIs ---

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: headers,
        body: jsonEncode(bookingData),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': resBody};
      }
      return {'success': false, 'error': resBody['error'] ?? 'فشل إرسال طلب الحجز'};
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  Future<List<dynamic>> getBookingsForUser(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/bookings/user/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading customer bookings: $e');
    }
    return [];
  }

  Future<List<dynamic>> getBookingsForCraftsman(String craftsmanId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/bookings/craftsman/$craftsmanId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading craftsman bookings: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/bookings/$bookingId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': resBody};
      }
      return {'success': false, 'error': resBody['error'] ?? 'فشل تعديل حالة الحجز'};
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  // --- Todo/Task Checklist APIs ---

  Future<List<dynamic>> getTodosForUser(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/todos/user/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading todos: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createTodo(String userId, String title) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/todos'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'title': title}),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': resBody};
      }
      return {'success': false, 'error': resBody['error'] ?? 'فشل إضافة المهمة'};
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateTodo(String id, {String? title, bool? completed}) async {
    try {
      final headers = await _getHeaders();
      final bodyData = <String, dynamic>{};
      if (title != null) bodyData['title'] = title;
      if (completed != null) bodyData['completed'] = completed;

      final response = await http.put(
        Uri.parse('$baseUrl/api/todos/$id'),
        headers: headers,
        body: jsonEncode(bodyData),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': resBody};
      }
      return {'success': false, 'error': resBody['error'] ?? 'فشل تعديل المهمة'};
    } catch (e) {
      return {'success': false, 'error': 'فشل الاتصال بالخادم'};
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/todos/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error deleting todo: $e');
    }
    return false;
  }

  // --- Admin Panel Dashboard APIs ---

  Future<Map<String, dynamic>?> getAdminStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/admin/stats'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching admin stats: $e');
    }
    return null;
  }

  Future<List<dynamic>> getAdminUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/admin/users'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading admin users: $e');
    }
    return [];
  }

  Future<bool> deleteUser(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/api/admin/users/$id'), headers: headers);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error deleting user by admin: $e');
    }
    return false;
  }

  Future<List<dynamic>> getAdminCraftsmen() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/admin/craftsmen'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading admin craftsmen: $e');
    }
    return [];
  }

  Future<bool> deleteCraftsman(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/api/admin/craftsmen/$id'), headers: headers);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error deleting craftsman by admin: $e');
    }
    return false;
  }

  Future<bool> toggleCraftsmanApproval(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(Uri.parse('$baseUrl/api/admin/craftsmen/$id/approve'), headers: headers);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error toggling craftsman approval by admin: $e');
    }
    return false;
  }

  Future<List<dynamic>> getAdminBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/admin/bookings'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading admin bookings: $e');
    }
    return [];
  }
}
