import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  // Premium design colors (Deep royal violet and neon accents)
  final Color primaryDark = const Color(0xFF1E0B36);
  final Color accentViolet = const Color(0xFF8A2BE2);
  final Color neonAmethyst = const Color(0xFFDDA0DD);
  final Color cardBg = const Color(0xFF2C1654);
  final Color successColor = const Color(0xFF00FF7F);
  final Color errorColor = const Color(0xFFFF4500);

  // States
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalCraftsmen': 0,
    'totalBookings': 0,
    'estimatedRevenue': 0
  };
  List<dynamic> _users = [];
  List<dynamic> _craftsmen = [];
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    });
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final statsData = await _apiService.getAdminStats();
      final usersList = await _apiService.getAdminUsers();
      final craftsmenList = await _apiService.getAdminCraftsmen();
      final bookingsList = await _apiService.getAdminBookings();

      setState(() {
        if (statsData != null) {
          _stats = statsData;
        }
        _users = usersList;
        _craftsmen = craftsmenList;
        _bookings = bookingsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('حدث خطأ أثناء تحميل البيانات ❌', errorColor);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // --- Administrative actions ---

  Future<void> _handleDeleteUser(String id, String name) async {
    final confirm = await _showConfirmDialog('حذف حساب العميل', 'هل أنت متأكد من رغبتك في حذف حساب العميل "$name" نهائياً؟');
    if (confirm) {
      final success = await _apiService.deleteUser(id);
      if (success) {
        _showSnackBar('تم حذف حساب العميل بنجاح ✅', successColor);
        _loadDashboardData();
      } else {
        _showSnackBar('فشل حذف الحساب ❌', errorColor);
      }
    }
  }

  Future<void> _handleDeleteCraftsman(String id, String name) async {
    final confirm = await _showConfirmDialog('حذف حساب الحرفي', 'هل أنت متأكد من حذف حساب الحرفي "$name"؟ سيتم حذف جميع الحجوزات المرتبطة به أيضاً.');
    if (confirm) {
      final success = await _apiService.deleteCraftsman(id);
      if (success) {
        _showSnackBar('تم حذف حساب الحرفي بنجاح ✅', successColor);
        _loadDashboardData();
      } else {
        _showSnackBar('فشل حذف الحساب ❌', errorColor);
      }
    }
  }

  Future<void> _handleToggleCraftsmanApproval(String id, String name) async {
    final success = await _apiService.toggleCraftsmanApproval(id);
    if (success) {
      _showSnackBar('تم تعديل حالة الحرفي "$name" بنجاح ✅', successColor);
      _loadDashboardData();
    } else {
      _showSnackBar('فشل تعديل الحالة ❌', errorColor);
    }
  }

  Future<void> _handleCancelBooking(String id) async {
    final confirm = await _showConfirmDialog('إلغاء الحجز', 'هل أنت متأكد من إلغاء هذا الطلب كمسؤول؟');
    if (confirm) {
      final res = await _apiService.updateBookingStatus(id, 'cancelled');
      if (res['success'] == true) {
        _showSnackBar('تم إلغاء الحجز بنجاح ✅', successColor);
        _loadDashboardData();
      } else {
        _showSnackBar(res['error'] ?? 'فشل إلغاء الحجز ❌', errorColor);
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(content, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- UI Elements ---

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: _buildAppBar(),
        bottomNavigationBar: _buildBottomTabs(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStatsTab(),
                  _buildUsersTab(),
                  _buildCraftsmenTab(),
                  _buildBookingsTab(),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: cardBg.withOpacity(0.5),
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.dashboard_customize_rounded, color: Colors.purpleAccent),
          SizedBox(width: 10),
          Text(
            'لوحة تحكم حِرَفي 👑',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          onPressed: _loadDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          onPressed: () async {
            await _apiService.logout();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.9),
        border: Border(top: BorderSide(color: accentViolet.withOpacity(0.3), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: neonAmethyst,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(icon: Icon(Icons.insights_rounded), text: 'الإحصائيات'),
          Tab(icon: Icon(Icons.people_alt_rounded), text: 'العملاء'),
          Tab(icon: Icon(Icons.handyman_rounded), text: 'الحرفيين'),
          Tab(icon: Icon(Icons.assignment_turned_in_rounded), text: 'الحجوزات'),
        ],
      ),
    );
  }

  // --- STATS TAB ---

  Widget _buildStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: accentViolet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أداء المنصة العام 📈',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'متابعة فورية للحركة والنمو الإجمالي للتطبيق',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 25),
            
            // Grid of stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.25,
              children: [
                _buildStatItem('إجمالي العملاء', _stats['totalUsers'].toString(), Icons.group_rounded, Colors.blueAccent),
                _buildStatItem('إجمالي الحرفيين', _stats['totalCraftsmen'].toString(), Icons.handyman_rounded, Colors.purpleAccent),
                _buildStatItem('الحجوزات والطلبات', _stats['totalBookings'].toString(), Icons.calendar_month_rounded, Colors.orangeAccent),
                _buildStatItem('العائد التقديري للمنصة', '${_stats['estimatedRevenue']} ج.م', Icons.wallet_rounded, successColor),
              ],
            ),
            const SizedBox(height: 35),
            
            const Text(
              'أحدث الحجوزات المضافة 🔔',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _bookings.isEmpty
                ? _buildEmptyState('لا يوجد حجوزات مسجلة حالياً')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bookings.length > 5 ? 5 : _bookings.length,
                    itemBuilder: (context, index) {
                      var booking = _bookings[index];
                      return _buildRecentBookingCard(booking);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(icon, size: 70, color: color.withOpacity(0.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      Icon(icon, color: color, size: 20),
                    ],
                  ),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'new';
    Color statColor = Colors.orangeAccent;
    String statusAr = 'قيد المراجعة';

    if (status == 'confirmed') {
      statColor = Colors.blueAccent;
      statusAr = 'مؤكد';
    } else if (status == 'completed') {
      statColor = successColor;
      statusAr = 'منجز';
    } else if (status == 'cancelled') {
      statColor = errorColor;
      statusAr = 'ملغى';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentViolet.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 5),
              Text(
                'العميل: ${data['customerName']} 👤  |  الحرفي: ${data['craftsmanName']} 🛠️',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statColor.withOpacity(0.3)),
            ),
            child: Text(
              statusAr,
              style: TextStyle(color: statColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- USERS MANAGEMENT TAB ---

  Widget _buildUsersTab() {
    final filtered = _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final city = (user['city'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          city.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('بحث عن العملاء بالاسم أو الإيميل...'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('لا يوجد نتائج متطابقة')
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    var user = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: accentViolet.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text('البريد: ${user['email']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 3),
                                Text('الهاتف: ${user['phone']}  |  المدينة: ${user['city']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_forever_rounded, color: errorColor),
                            onPressed: () => _handleDeleteUser(user['_id'], user['name']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- CRAFTSMEN MANAGEMENT TAB ---

  Widget _buildCraftsmenTab() {
    final filtered = _craftsmen.where((cr) {
      final name = (cr['name'] ?? '').toString().toLowerCase();
      final cat = (cr['category'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || cat.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('بحث عن الحرفيين بالاسم أو التخصص...'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('لا يوجد نتائج متطابقة')
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    var cr = filtered[index];
                    bool available = cr['isAvailable'] ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: available ? successColor.withOpacity(0.2) : accentViolet.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cr['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: available ? successColor.withOpacity(0.12) : errorColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: available ? successColor.withOpacity(0.3) : errorColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      available ? 'نشط ومتاح' : 'غير متوفر',
                                      style: TextStyle(color: available ? successColor : errorColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('⭐ ${cr['rating']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('التخصص: ${cr['category']}', style: TextStyle(color: neonAmethyst, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('الخبرة: ${cr['experience']} سنة  |  السعر: ${cr['price']} ج.م/ساعة', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('البريد: ${cr['email']}  |  الهاتف: ${cr['phone']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          const Divider(color: Colors.white12, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _handleToggleCraftsmanApproval(cr['_id'], cr['name']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: available ? errorColor.withOpacity(0.2) : successColor.withOpacity(0.2),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(
                                  available ? Icons.block_flipped : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: available ? errorColor : successColor,
                                ),
                                label: Text(
                                  available ? 'حظر مؤقت' : 'تفعيل الإتاحة',
                                  style: TextStyle(color: available ? errorColor : successColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: Icon(Icons.delete_forever_rounded, color: errorColor),
                                onPressed: () => _handleDeleteCraftsman(cr['_id'], cr['name']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- ALL BOOKINGS MONITOR TAB ---

  Widget _buildBookingsTab() {
    final filtered = _bookings.where((bk) {
      final title = (bk['title'] ?? '').toString().toLowerCase();
      final cName = (bk['customerName'] ?? '').toString().toLowerCase();
      final crName = (bk['craftsmanName'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          cName.contains(_searchQuery.toLowerCase()) ||
          crName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('بحث في الحجوزات بالاسم أو نوع الخدمة...'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('لا يوجد حجوزات متطابقة')
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    var bk = filtered[index];
                    String status = bk['status'] ?? 'new';
                    Color statColor = Colors.orangeAccent;
                    String statusAr = 'انتظار الموافقة';
                    
                    if (status == 'confirmed') {
                      statColor = Colors.blueAccent;
                      statusAr = 'مقبول / مؤكد';
                    } else if (status == 'completed') {
                      statColor = successColor;
                      statusAr = 'منتهي ومكتمل';
                    } else if (status == 'cancelled') {
                      statColor = errorColor;
                      statusAr = 'ملغى';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: statColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bk['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  statusAr,
                                  style: TextStyle(color: statColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('التفاصيل: ${bk['description'] ?? bk['serviceType']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            'الموعد: ${bk['appointmentDate'].toString().split('T')[0]} في تمام ${bk['appointmentTime']}',
                            style: TextStyle(color: neonAmethyst, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text('العميل: ${bk['customerName']} (${bk['customerPhone']})', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          Text('الموقع: ${bk['location']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          Text('الحرفي المستهدف: ${bk['craftsmanName']} (${bk['craftsmanCategory']})', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          const Divider(color: Colors.white12, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'التكلفة: ${bk['expectedPrice']} ج.م',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              status != 'cancelled' && status != 'completed'
                                  ? ElevatedButton.icon(
                                      onPressed: () => _handleCancelBooking(bk['_id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: errorColor.withOpacity(0.2),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                                      label: const Text('إلغاء الحجز', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  : Container(),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildSearchBar(String hint) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentViolet.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.purpleAccent),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 70, color: Colors.white10),
          const SizedBox(height: 15),
          Text(
            msg,
            style: const TextStyle(color: Colors.white30, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
