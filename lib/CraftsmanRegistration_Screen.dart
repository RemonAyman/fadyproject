import 'package:flutter/material.dart';
import 'craftsmen_homescreen.dart';
import 'api_service.dart';

class CraftsmanRegistrationScreen extends StatefulWidget {
  const CraftsmanRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<CraftsmanRegistrationScreen> createState() => _CraftsmanRegistrationScreenState();
}

class _CraftsmanRegistrationScreenState extends State<CraftsmanRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  String? _selectedCategory;
  
  final List<String> _categories = [
    'سباك', 'كهربائي', 'نجار', 'دهان', 'نقاش', 'سيراميك', 'تكييف', 'أعمال ألمنيوم', 'حداد', 'أخرى',
  ];

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF2ECC71);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء التأكد من البيانات والموافقة على الشروط')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final int exp = int.tryParse(_experienceController.text.trim()) ?? 0;

      final result = await ApiService().registerCraftsman(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        category: _selectedCategory!,
        price: price,
        experience: exp,
        password: _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء حسابك بنجاح! 🎉'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/craftsman_home', (route) => false);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'فشل التسجيل'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الاتصال بالخادم: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: _isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputCard(
                            child: Column(
                              children: [
                                _buildTextField(_nameController, 'الاسم الكامل', Icons.person_outline),
                                const Divider(),
                                _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                                const Divider(),
                                _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputCard(
                            child: Column(
                              children: [
                                _buildCategoryDropdown(),
                                const Divider(),
                                _buildTextField(_priceController, 'السعر المتوقع بالساعة', Icons.monetization_on_outlined, keyboardType: TextInputType.number),
                                const Divider(),
                                _buildTextField(_experienceController, 'سنوات الخبرة', Icons.history_edu_outlined, keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputCard(
                            child: _buildTextField(
                              _passwordController, 
                              'كلمة المرور', 
                              Icons.lock_outline, 
                              obscureText: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTermsCheckbox(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets المساعدة للجماليات ---

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
          ),
          child: const Center(
            child: Icon(Icons.construction, size: 70, color: Colors.white),
          ),
        ),
        title: const Text('تسجيل الحرفيين', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(20),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      hint: const Text('اختر التخصص'),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.work_outline, color: primaryColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: _agreeToTerms,
      onChanged: (v) => setState(() => _agreeToTerms = v!),
      title: const Text('أوافق على الشروط والسياسات الخاصة بالتطبيق', style: TextStyle(fontSize: 13)),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: primaryColor,
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Text('إنشاء حساب حرفي الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}