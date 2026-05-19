import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'api_service.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({Key? key}) : super(key: key);

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);
  final Color warningColor = Colors.orange;
  final Color completeColor = const Color(0xFF4CAF50);

  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final uid = await ApiService().getUserId();
      if (uid != null) {
        _userId = uid;
        final list = await ApiService().getBookingsForUser(uid);
        setState(() {
          _bookings = list;
          // Sort descending (newest first)
          _bookings.sort((a, b) {
            final aDate = DateTime.tryParse(a['createdAt'] ?? a['appointmentDate'] ?? '') ?? DateTime.now();
            final bDate = DateTime.tryParse(b['createdAt'] ?? b['appointmentDate'] ?? '') ?? DateTime.now();
            return bDate.compareTo(aDate);
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('حجوزاتي'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _userId == null
              ? const Center(child: Text('يجب تسجيل الدخول'))
              : _bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد لديك حجوزات حالياً',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final data = _bookings[index] as Map<String, dynamic>;
                          return _buildBookingCard(context, data);
                        },
                      ),
                    ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> data) {
    final date = DateTime.tryParse(data['appointmentDate'] ?? '');
    final dateStr = date != null 
        ? intl.DateFormat('yyyy/MM/dd', 'ar').format(date) 
        : 'غير محدد';
    final timeStr = data['appointmentTime'] ?? 'غير محدد';
    final status = data['status'] ?? 'new';

    Color statusColor;
    String statusText;

    switch (status) {
      case 'new':
        statusColor = warningColor;
        statusText = 'قيد المراجعة';
        break;
      case 'confirmed':
        statusColor = primaryColor;
        statusText = 'مؤكد';
        break;
      case 'completed':
        statusColor = completeColor;
        statusText = 'مكتمل';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'ملغى';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير معروف';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['serviceType'] ?? 'خدمة',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'الحرفي: ${data['craftsmanName'] ?? 'غير معروف'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.work, 'التخصص: ${data['craftsmanCategory'] ?? 'عام'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'الموعد: $dateStr - $timeStr'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'الموقع: ${data['location'] ?? 'غير محدد'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'السعر المتوقع: ${data['expectedPrice'] ?? 0} ج.م'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}
