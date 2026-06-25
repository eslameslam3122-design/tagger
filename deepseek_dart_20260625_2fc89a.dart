import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: LicenseCheckScreen(),
    ),
  );
}

// ============================================================
// 🎨 ثيم التطبيق المتقدم
// ============================================================

ThemeData _buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFF9800),
    scaffoldBackgroundColor: const Color(0xFF0A0A0F),
    fontFamily: 'Tajawal',
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A24),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2C2C35), width: 0.5),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF16161D),
      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
      labelStyle: TextStyle(color: Color(0xFFFF9800)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFF2C2C35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFFF9800), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0F),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF12121A),
      selectedItemColor: Color(0xFFFF9800),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

// ============================================================
// 🔐 نظام التشفير والترخيص (المعدل بالكامل)
// ============================================================

class SecureLicense {
  static String _getMasterKey() => "T4g3r-Ult1m4t3-S3cur3-K3y-2026!@#XyZ#@!-Secure";

  static String _getDynamicKey() {
    DateTime now = DateTime.now();
    String datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    String key = _getMasterKey() + datePart;
    // ✅ التصحيح: تحويل القائمة لقابلة للتعديل
    List<int> chars = key.codeUnits.toList();
    chars.shuffle(Random(now.day + now.month + now.year));
    return String.fromCharCodes(chars).substring(0, 32);
  }

  static String encryptLicense(Map<String, dynamic> data) {
    try {
      String jsonData = json.encode(data);
      String key = _getDynamicKey();
      List<int> bytes = utf8.encode(jsonData);
      List<int> keyBytes = utf8.encode(key);
      List<int> encrypted = [];
      for (int i = 0; i < bytes.length; i++) {
        int keyIndex = i % keyBytes.length;
        int xorVal = bytes[i] ^ keyBytes[keyIndex];
        xorVal = (xorVal + (i * 13) + (i ~/ 3)) % 256;
        encrypted.add(xorVal);
      }
      List<int> reversed = [];
      for (int i = 0; i < encrypted.length; i++) {
        int index = (i * 7 + 3) % encrypted.length;
        reversed.add(encrypted[index]);
      }
      String signature = _generateSignature(jsonData);
      Map<String, dynamic> finalData = {
        "data": base64.encode(reversed),
        "sig": signature,
        "ver": "2.0",
        "ts": DateTime.now().millisecondsSinceEpoch,
      };
      String finalJson = json.encode(finalData);
      List<int> finalBytes = utf8.encode(finalJson);
      List<int> finalEncrypted = [];
      for (int i = 0; i < finalBytes.length; i++) {
        finalEncrypted.add(finalBytes[i] ^ (i * 31 % 256));
      }
      return base64.encode(finalEncrypted);
    } catch (e) {
      throw Exception("فشل تشفير الترخيص: $e");
    }
  }

  static Map<String, dynamic>? decryptLicense(String encodedKey) {
    try {
      List<int> encrypted = base64.decode(encodedKey.trim());
      List<int> decryptedBytes = [];
      for (int i = 0; i < encrypted.length; i++) {
        decryptedBytes.add(encrypted[i] ^ (i * 31 % 256));
      }
      String jsonStr = utf8.decode(decryptedBytes);
      Map<String, dynamic> wrapper = json.decode(jsonStr);
      String encodedData = wrapper["data"];
      String signature = wrapper["sig"];
      List<int> reversedData = base64.decode(encodedData);
      List<int> originalOrder = List.filled(reversedData.length, 0);
      for (int i = 0; i < reversedData.length; i++) {
        int index = (i * 7 + 3) % reversedData.length;
        originalOrder[index] = reversedData[i];
      }
      String key = _getDynamicKey();
      List<int> keyBytes = utf8.encode(key);
      List<int> decrypted = [];
      for (int i = 0; i < originalOrder.length; i++) {
        int val = originalOrder[i];
        val = (val - (i * 13) - (i ~/ 3)) % 256;
        if (val < 0) val += 256;
        int keyIndex = i % keyBytes.length;
        int xorVal = val ^ keyBytes[keyIndex];
        decrypted.add(xorVal);
      }
      String jsonData = utf8.decode(decrypted);
      String calculatedSig = _generateSignature(jsonData);
      if (calculatedSig != signature) return null;
      return json.decode(jsonData);
    } catch (e) {
      return null;
    }
  }

  static String _generateSignature(String data) {
    String key = _getMasterKey() + "SIG2026!@#";
    List<int> bytes = utf8.encode(data + key);
    int hash = 0x811c9dc5;
    for (int i = 0; i < bytes.length; i++) {
      hash ^= bytes[i];
      hash *= 0x01000193;
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static LicenseValidationResult validateLicense(String encodedKey, String deviceHardwareId) {
    try {
      Map<String, dynamic>? decrypted = decryptLicense(encodedKey);
      if (decrypted == null) {
        return LicenseValidationResult(valid: false, message: "❌ كود التفعيل غير صالح أو تم التلاعب به!");
      }
      if (decrypted["hwid"] != deviceHardwareId) {
        return LicenseValidationResult(valid: false, message: "❌ هذا الكود مخصص لجهاز آخر!");
      }
      DateTime expiry = DateTime.parse(decrypted["expiry"]);
      if (DateTime.now().isAfter(expiry)) {
        return LicenseValidationResult(
          valid: false,
          message: "❌ انتهت صلاحية الترخيص! تاريخ الانتهاء: ${expiry.toLocal()}",
        );
      }
      if (decrypted["version"] != "2.0") {
        return LicenseValidationResult(valid: false, message: "❌ إصدار الترخيص غير متوافق!");
      }
      return LicenseValidationResult(
        valid: true,
        message: "✅ ترخيص صالح",
        licenseType: decrypted["type"],
        expiryDate: expiry,
        data: decrypted,
      );
    } catch (e) {
      return LicenseValidationResult(valid: false, message: "❌ خطأ في قراءة الترخيص: $e");
    }
  }

  static String generateLicense({
    required String hardwareId,
    required String licenseType,
    required DateTime expiryDate,
  }) {
    Map<String, dynamic> data = {
      "hwid": hardwareId,
      "type": licenseType,
      "expiry": expiryDate.toIso8601String(),
      "issued": DateTime.now().toIso8601String(),
      "version": "2.0",
    };
    return encryptLicense(data);
  }
}

class LicenseValidationResult {
  final bool valid;
  final String message;
  final String? licenseType;
  final DateTime? expiryDate;
  final Map<String, dynamic>? data;
  LicenseValidationResult({
    required this.valid,
    required this.message,
    this.licenseType,
    this.expiryDate,
    this.data,
  });
}

// ============================================================
// 🆔 توليد Hardware ID
// ============================================================

String getHardwareId() {
  int timestamp = DateTime.now().millisecondsSinceEpoch;
  int hour = DateTime.now().hour;
  int minute = DateTime.now().minute;
  int dayOfYear = DateTime.now().day;
  int seed1 = (timestamp % 1000000);
  int seed2 = (dayOfYear * 31 + hour * 17 + minute * 13);
  int seed3 = (554321 + 987654).abs();
  int finalSeed = ((seed1 * 7) + (seed2 * 11) + (seed3 * 3)) % 999999;
  String checksum = (finalSeed % 97).toString().padLeft(2, '0');
  return "TGR-HW-${finalSeed.toString().padLeft(6, '0')}-$checksum";
}

// ============================================================
// 📱 شاشة التحقق من الترخيص
// ============================================================

class LicenseCheckScreen extends StatefulWidget {
  @override
  _LicenseCheckScreenState createState() => _LicenseCheckScreenState();
}

class _LicenseCheckScreenState extends State<LicenseCheckScreen> {
  final _keyCtrl = TextEditingController();
  String _statusMessage = "🔐 أدخل كود التفعيل لتشغيل البرنامج";
  late String hardwareId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    hardwareId = getHardwareId();
    _checkCurrentLicense();
  }

  Future<void> _checkCurrentLicense() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedKey = prefs.getString('activation_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      await _verifyKey(savedKey, isAutoCheck: true);
    }
  }

  Future<void> _verifyKey(String key, {bool isAutoCheck = false}) async {
    if (!isAutoCheck) setState(() => _isLoading = true);
    try {
      var result = SecureLicense.validateLicense(key.trim(), hardwareId);
      if (!result.valid) {
        _updateStatus(result.message);
        if (!isAutoCheck) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message), backgroundColor: Colors.red),
          );
        }
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activation_key', key.trim());
      await prefs.setString('license_type', result.licenseType!);
      await prefs.setString('license_expiry', result.expiryDate!.toIso8601String());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              licenseType: result.licenseType!,
              expiryDate: result.expiryDate!,
            ),
          ),
        );
      }
    } catch (e) {
      _updateStatus("❌ حدث خطأ أثناء التحقق من الترخيص!");
    } finally {
      if (!isAutoCheck) setState(() => _isLoading = false);
    }
  }

  void _updateStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 80, color: Color(0xFFFF9800)),
                const SizedBox(height: 16),
                const Text("سيستم تاجر Ultimate",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("نظام إدارة الصيانة والبيع الذكي المشفر V3.0",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C2C35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("🆔 الجهاز: $hardwareId",
                          style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: hardwareId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("📋 تم نسخ Hardware ID بنجاح!"), backgroundColor: Colors.green),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Colors.black),
                        label: const Text("نسخ المعرف",
                            style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _keyCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "🔑 انقش كود التفعيل هنا...",
                            prefixIcon: Icon(Icons.vpn_key, color: Color(0xFFFF9800)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
                            onPressed: _isLoading ? null : () => _verifyKey(_keyCtrl.text),
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text("🔓 تفعيل وتشغيل السيرفر أوفلاين",
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 🏠 الشاشة الرئيسية (مع صلاحيات الترخيص)
// ============================================================

class MainScreen extends StatefulWidget {
  final String licenseType;
  final DateTime expiryDate;
  const MainScreen({super.key, required this.licenseType, required this.expiryDate});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ✅ الأقسام المتاحة حسب الترخيص
  List<Widget> get _screens {
    List<Widget> screens = [];
    if (widget.licenseType.contains('CASHIER') || widget.licenseType == 'FULL') {
      screens.add(const PosScreen());
    }
    if (widget.licenseType.contains('REPAIR') || widget.licenseType == 'FULL') {
      screens.add(const RepairScreen());
    }
    if (widget.licenseType.contains('WALLETS') || widget.licenseType == 'FULL') {
      screens.add(const WalletScreen());
    }
    screens.add(const CustomersScreen());
    screens.add(const ExpensesScreen());
    screens.add(const DailyScreen());
    screens.add(const SettingsScreen());
    return screens;
  }

  List<String> get _titles {
    List<String> titles = [];
    if (widget.licenseType.contains('CASHIER') || widget.licenseType == 'FULL') titles.add('البيع');
    if (widget.licenseType.contains('REPAIR') || widget.licenseType == 'FULL') titles.add('الصيانة');
    if (widget.licenseType.contains('WALLETS') || widget.licenseType == 'FULL') titles.add('المحافظ');
    titles.add('العملاء');
    titles.add('المصروفات');
    titles.add('اليومية');
    titles.add('الإعدادات');
    return titles;
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    final titles = _titles;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => RepairProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => DailyProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_currentIndex]),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Text(
                  "🔒 ${widget.licenseType}",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: titles.map((title) {
            IconData icon;
            switch (title) {
              case 'البيع': icon = Icons.shopping_cart; break;
              case 'الصيانة': icon = Icons.build; break;
              case 'المحافظ': icon = Icons.wallet; break;
              case 'العملاء': icon = Icons.people; break;
              case 'المصروفات': icon = Icons.money_off; break;
              case 'اليومية': icon = Icons.calendar_today; break;
              case 'الإعدادات': icon = Icons.settings; break;
              default: icon = Icons.star;
            }
            return BottomNavigationBarItem(icon: Icon(icon), label: title);
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// 📦 نموذج بيانات المنتج (لنقطة البيع)
// ============================================================

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  Product({required this.id, required this.name, required this.price, required this.imageUrl, this.quantity = 0});
}

// ============================================================
// 🛒 مزود حالة العربة (نقطة البيع)
// ============================================================

class CartProvider extends ChangeNotifier {
  List<Product> _cartItems = [];
  String customerName = '';
  String customerPhone = '';
  String _searchQuery = '';

  List<Product> get cartItems => _cartItems;
  String get searchQuery => _searchQuery;
  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) return dummyProducts;
    return dummyProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere((p) => p.id == product.id);
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(Product(id: product.id, name: product.name, price: product.price, imageUrl: product.imageUrl, quantity: 1));
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int newQty) {
    final index = _cartItems.indexWhere((p) => p.id == id);
    if (index != -1) {
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    customerName = '';
    customerPhone = '';
    notifyListeners();
  }

  void setCustomer(String name, String phone) {
    customerName = name;
    customerPhone = phone;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

final List<Product> dummyProducts = [
  Product(id: '1', name: 'شاشة آيفون 13', price: 850.0, imageUrl: 'https://picsum.photos/seed/iphone13/200/200'),
  Product(id: '2', name: 'شاشة آيفون 14', price: 950.0, imageUrl: 'https://picsum.photos/seed/iphone14/200/200'),
  Product(id: '3', name: 'بطارية سامسونج S22', price: 350.0, imageUrl: 'https://picsum.photos/seed/battery/200/200'),
  Product(id: '4', name: 'بطارية سامسونج S23', price: 450.0, imageUrl: 'https://picsum.photos/seed/battery2/200/200'),
  Product(id: '5', name: 'كابل شحن سريع', price: 120.0, imageUrl: 'https://picsum.photos/seed/cable/200/200'),
  Product(id: '6', name: 'كابل شحن نوع C', price: 150.0, imageUrl: 'https://picsum.photos/seed/cable2/200/200'),
  Product(id: '7', name: 'سماعة أصلية', price: 250.0, imageUrl: 'https://picsum.photos/seed/headphone/200/200'),
  Product(id: '8', name: 'سماعة لاسلكية', price: 350.0, imageUrl: 'https://picsum.photos/seed/headphone2/200/200'),
];

// ============================================================
// 🏪 القسم الأول: نقطة البيع
// ============================================================

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Consumer<CartProvider>(
            builder: (_, provider, __) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '🔍 ابحث عن منتج...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9800)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: const Color(0xFF16161D),
                ),
                onChanged: provider.setSearchQuery,
              ),
            ),
          ),
          const CustomerSection(),
          const Expanded(child: ProductsGrid()),
          const CartSummary(),
        ],
      ),
    );
  }
}

class CustomerSection extends StatelessWidget {
  const CustomerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'اسم العميل',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF16161D),
              ),
              onChanged: (val) => cart.setCustomer(val, cart.customerPhone),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'رقم التليفون',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF16161D),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (val) => cart.setCustomer(cart.customerName, val),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsGrid extends StatelessWidget {
  const ProductsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final products = cart.filteredProducts;

    if (products.isEmpty) {
      return const Center(child: Text('لا توجد منتجات مطابقة للبحث'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, index) {
        final product = products[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              final cartProvider = Provider.of<CartProvider>(ctx, listen: false);
              cartProvider.addToCart(product);
              if (cartProvider.customerName.isNotEmpty && cartProvider.customerPhone.isNotEmpty) {
                Provider.of<CustomersProvider>(ctx, listen: false).addCustomer(
                  name: cartProvider.customerName,
                  phone: cartProvider.customerPhone,
                );
              }
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('تم إضافة ${product.name}'), duration: const Duration(seconds: 1)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(product.imageUrl, height: 80, width: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                Text('${product.price.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CartSummary extends StatelessWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('عدد الأصناف: ${cart.cartItems.length}', style: const TextStyle(fontSize: 14)),
              Text('الإجمالي: ${cart.totalPrice.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
            ],
          ),
          Row(
            children: [
              if (cart.cartItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                  onPressed: () {
                    cart.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح الفاتورة')));
                  },
                ),
              ElevatedButton.icon(
                onPressed: cart.cartItems.isEmpty ? null : () => _showInvoiceDialog(context),
                icon: const Icon(Icons.receipt),
                label: const Text('عرض الفاتورة'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (cart.customerName.isNotEmpty && cart.customerPhone.isNotEmpty) {
      Provider.of<CustomersProvider>(context, listen: false).addCustomer(
        name: cart.customerName,
        phone: cart.customerPhone,
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: const [Icon(Icons.receipt_long, color: Color(0xFFFF9800)), SizedBox(width: 8), Text('الفاتورة النهائية')]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('العميل: ${cart.customerName.isNotEmpty ? cart.customerName : "غير محدد"}'),
                    Text('الهاتف: ${cart.customerPhone.isNotEmpty ? cart.customerPhone : "غير محدد"}'),
                  ],
                ),
              ),
              const Divider(height: 20, color: Colors.grey),
              ...cart.cartItems.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${p.name} ×${p.quantity}'),
                    Text('${(p.price * p.quantity).toStringAsFixed(2)} ج.م'),
                  ],
                ),
              )),
              const Divider(height: 20, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('${cart.totalPrice.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFF9800))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _sendInvoice(context);
            },
            icon: const Icon(Icons.send),
            label: const Text('إرسال للواتساب'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _sendInvoice(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (settings.whatsappNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى تسجيل رقم واتساب في الإعدادات أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    String message = settings.buildMessage(
      customerName: cart.customerName,
      customerPhone: cart.customerPhone,
      items: cart.cartItems,
      total: cart.totalPrice,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('معاينة الرسالة'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(message, style: const TextStyle(fontSize: 14), textDirection: TextDirection.rtl),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              cart.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم إرسال الفاتورة إلى ${settings.whatsappNumber}'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('تأكيد الإرسال'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 📦 القسم الثاني: المخزن والجرد
// ============================================================

class StoreProduct {
  String id;
  String name;
  double price;
  String category;
  String imageUrl;
  int stockQuantity;
  StoreProduct({required this.id, required this.name, required this.price, required this.category, this.imageUrl = '', this.stockQuantity = 0});
}

class StoreProvider extends ChangeNotifier {
  List<StoreProduct> _products = [];
  List<String> _categories = ['شاشات', 'بطاريات', 'كابلات', 'سماعات', 'أكسسوارات'];
  List<StoreProduct> get products => _products;
  List<String> get categories => _categories;

  StoreProvider() {
    _products.addAll([
      StoreProduct(id: '1', name: 'شاشة آيفون 13', price: 850, category: 'شاشات', imageUrl: 'https://picsum.photos/seed/store1/200/200', stockQuantity: 10),
      StoreProduct(id: '2', name: 'بطارية سامسونج S22', price: 350, category: 'بطاريات', imageUrl: 'https://picsum.photos/seed/store2/200/200', stockQuantity: 15),
      StoreProduct(id: '3', name: 'كابل شحن سريع', price: 120, category: 'كابلات', imageUrl: 'https://picsum.photos/seed/store3/200/200', stockQuantity: 30),
    ]);
  }

  void addProduct(StoreProduct product) { _products.add(product); notifyListeners(); }
  void deleteProduct(String id) { _products.removeWhere((p) => p.id == id); notifyListeners(); }
  void updateStock(String id, int newQuantity) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) { _products[index].stockQuantity = newQuantity; notifyListeners(); }
  }
  void addCategory(String category) { if (!_categories.contains(category)) { _categories.add(category); notifyListeners(); } }
}

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('المخزن والجرد'), bottom: const TabBar(tabs: [Tab(text: 'المنتجات'), Tab(text: 'الجرد')])),
        body: const TabBarView(children: [ProductsManagementTab(), InventoryTab()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddProductDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = 'شاشات';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة منتج جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المنتج *')),
            const SizedBox(height: 8),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر *'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'الكمية *'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: Provider.of<StoreProvider>(context, listen: false).categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => selectedCategory = val!,
              decoration: const InputDecoration(labelText: 'المجموعة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || priceController.text.isEmpty || stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء جميع الحقول')));
                return;
              }
              final store = Provider.of<StoreProvider>(context, listen: false);
              store.addProduct(StoreProduct(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                price: double.parse(priceController.text),
                category: selectedCategory,
                stockQuantity: int.parse(stockController.text),
                imageUrl: 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200',
              ));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم الإضافة')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class ProductsManagementTab extends StatelessWidget {
  const ProductsManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreProvider>(context);
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: store.products.length,
      itemBuilder: (ctx, index) {
        final product = store.products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
            ),
            title: Text(product.name),
            subtitle: Text('${product.price.toStringAsFixed(2)} ج.م - ${product.category} - ${product.stockQuantity} وحدة'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () { store.deleteProduct(product.id); },
            ),
          ),
        );
      },
    );
  }
}

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StoreProvider>(context);
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: store.products.length,
      itemBuilder: (ctx, index) {
        final product = store.products[index];
        final controller = TextEditingController(text: product.stockQuantity.toString());
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('المجموعة: ${product.category}'),
                      Text('المخزن: ${product.stockQuantity} وحدة'),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'العدد الفعلي', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        store.updateStock(product.id, int.parse(val));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 🔧 القسم الثالث: الصيانة
// ============================================================

class RepairDevice {
  final String id;
  String customerName;
  String customerPhone;
  String deviceBrand;
  String deviceModel;
  String deviceCondition;
  DateTime receiveDate;
  DateTime? deliveryDate;
  String status;
  List<String> statusHistory;
  String notes;
  double estimatedPrice;
  double finalPrice;
  RepairDevice({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deviceBrand,
    required this.deviceModel,
    required this.deviceCondition,
    required this.receiveDate,
    this.deliveryDate,
    this.status = 'قيد الانتظار',
    this.statusHistory = const ['قيد الانتظار'],
    this.notes = '',
    this.estimatedPrice = 0,
    this.finalPrice = 0,
  });

  RepairDevice copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? deviceBrand,
    String? deviceModel,
    String? deviceCondition,
    DateTime? receiveDate,
    DateTime? deliveryDate,
    String? status,
    List<String>? statusHistory,
    String? notes,
    double? estimatedPrice,
    double? finalPrice,
  }) {
    return RepairDevice(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceCondition: deviceCondition ?? this.deviceCondition,
      receiveDate: receiveDate ?? this.receiveDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      notes: notes ?? this.notes,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }
}

class RepairProvider extends ChangeNotifier {
  List<RepairDevice> _devices = [];
  String _searchQuery = '';
  List<RepairDevice> get devices => _devices;
  String get searchQuery => _searchQuery;

  final List<String> _availableStatuses = ['قيد الانتظار', 'قيد الفحص', 'في الانتظار (قطع غيار)', 'قيد الصيانة', 'تم الإصلاح', 'بانتظار العميل', 'مكتمل', 'مرفوض'];
  List<String> get availableStatuses => _availableStatuses;

  final List<String> _deviceConditions = ['جيد', 'به خدوش', 'شاشة مكسورة', 'ظهر مكسور', 'لا يعمل', 'به ماء', 'به حرق', 'أخرى'];
  List<String> get deviceConditions => _deviceConditions;

  final List<String> _deviceBrands = ['Apple', 'Samsung', 'Huawei', 'Xiaomi', 'Oppo', 'Vivo', 'OnePlus', 'Nokia', 'Sony', 'LG', 'HTC', 'Google', 'Motorola', 'Realme', 'Infinix', 'أخرى'];
  List<String> get deviceBrands => _deviceBrands;

  RepairProvider() {
    _devices.addAll([
      RepairDevice(id: 'R001', customerName: 'أحمد محمد', customerPhone: '01012345678', deviceBrand: 'Apple', deviceModel: 'iPhone 13 Pro Max', deviceCondition: 'شاشة مكسورة', receiveDate: DateTime.now().subtract(const Duration(days: 2)), status: 'قيد الصيانة', statusHistory: ['قيد الانتظار', 'قيد الفحص', 'قيد الصيانة'], notes: 'الشاشة مكسورة بالكامل، تحتاج تغيير', estimatedPrice: 1200, finalPrice: 1000),
      RepairDevice(id: 'R002', customerName: 'سارة علي', customerPhone: '01123456789', deviceBrand: 'Samsung', deviceModel: 'Galaxy S22 Ultra', deviceCondition: 'به ماء', receiveDate: DateTime.now().subtract(const Duration(days: 5)), status: 'في الانتظار (قطع غيار)', statusHistory: ['قيد الانتظار', 'قيد الفحص', 'في الانتظار (قطع غيار)'], notes: 'تعرض الجهاز للماء، يحتاج تنظيف داخلي', estimatedPrice: 800),
      RepairDevice(id: 'R003', customerName: 'محمد خالد', customerPhone: '01234567890', deviceBrand: 'Xiaomi', deviceModel: 'Redmi Note 11', deviceCondition: 'لا يعمل', receiveDate: DateTime.now().subtract(const Duration(days: 1)), status: 'قيد الفحص', statusHistory: ['قيد الانتظار', 'قيد الفحص'], notes: 'الجهاز لا يعمل تماماً، يحتاج فحص شامل', estimatedPrice: 500),
    ]);
  }

  void addDevice(RepairDevice device) { _devices.add(device); notifyListeners(); }
  void updateDeviceStatus(String id, String newStatus) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) { _devices[index].status = newStatus; _devices[index].statusHistory.add(newStatus); notifyListeners(); }
  }
  void updateDevice(RepairDevice updatedDevice) {
    final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
    if (index != -1) { _devices[index] = updatedDevice; notifyListeners(); }
  }
  void deleteDevice(String id) { _devices.removeWhere((d) => d.id == id); notifyListeners(); }
  String generateDeviceId() { final count = _devices.length + 1; return 'R${count.toString().padLeft(3, '0')}'; }
  List<RepairDevice> get filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    final query = _searchQuery.toLowerCase();
    return _devices.where((device) =>
      device.customerName.toLowerCase().contains(query) ||
      device.customerPhone.contains(query) ||
      device.deviceModel.toLowerCase().contains(query) ||
      device.deviceBrand.toLowerCase().contains(query) ||
      device.id.toLowerCase().contains(query)
    ).toList();
  }
  void setSearchQuery(String query) { _searchQuery = query; notifyListeners(); }
  List<RepairDevice> getDevicesByStatus(String status) { return _devices.where((d) => d.status == status).toList(); }
  Map<String, int> getStatusCounts() {
    final Map<String, int> counts = {};
    for (var status in _availableStatuses) { counts[status] = _devices.where((d) => d.status == status).length; }
    return counts;
  }
}

class RepairScreen extends StatelessWidget {
  const RepairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('قسم الصيانة'), bottom: const TabBar(tabs: [Tab(text: 'الأجهزة'), Tab(text: 'الحالات'), Tab(text: 'بحث')])),
        body: const TabBarView(children: [DevicesTab(), StatusTab(), SearchTab()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDeviceDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final modelController = TextEditingController();
    final notesController = TextEditingController();
    final priceController = TextEditingController();
    String selectedBrand = 'Apple';
    String selectedCondition = 'جيد';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استلام جهاز جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل *')),
            const SizedBox(height: 8),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الموبيل *'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedBrand,
              items: Provider.of<RepairProvider>(context, listen: false).deviceBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => selectedBrand = val!,
              decoration: const InputDecoration(labelText: 'ماركة الجهاز *'),
            ),
            const SizedBox(height: 8),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'موديل الجهاز *')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCondition,
              items: Provider.of<RepairProvider>(context, listen: false).deviceConditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => selectedCondition = val!,
              decoration: const InputDecoration(labelText: 'حالة الجهاز *'),
            ),
            const SizedBox(height: 8),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر التقديري'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || phoneController.text.isEmpty || modelController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء الحقول المطلوبة')));
                return;
              }
              final provider = Provider.of<RepairProvider>(context, listen: false);
              final newId = provider.generateDeviceId();
              final device = RepairDevice(
                id: newId,
                customerName: nameController.text,
                customerPhone: phoneController.text,
                deviceBrand: selectedBrand,
                deviceModel: modelController.text,
                deviceCondition: selectedCondition,
                receiveDate: selectedDate,
                notes: notesController.text,
                estimatedPrice: double.tryParse(priceController.text) ?? 0,
              );
              provider.addDevice(device);
              Provider.of<CustomersProvider>(context, listen: false).addCustomer(
                name: device.customerName,
                phone: device.customerPhone,
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم استلام الجهاز - الكود: $newId'), backgroundColor: Colors.green),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RepairProvider>(context);
    return provider.devices.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.devices, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد أجهزة'),
            Text('اضغط على + لإضافة جهاز'),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.devices.length,
            itemBuilder: (ctx, index) {
              final device = provider.devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(device.status),
                    child: Text(device.id.replaceAll('R', ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('${device.customerName} - ${device.deviceBrand} ${device.deviceModel}'),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _getStatusColor(device.status).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(device.status, style: TextStyle(color: _getStatusColor(device.status), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text('الكود: ${device.id}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDeviceDialog(context, device),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text('هل أنت متأكد من حذف جهاز ${device.customerName}؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                                ElevatedButton(
                                  onPressed: () {
                                    provider.deleteDevice(device.id);
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الجهاز')));
                                  },
                                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الانتظار': return Colors.orange;
      case 'قيد الفحص': return Colors.blue;
      case 'في الانتظار (قطع غيار)': return Colors.purple;
      case 'قيد الصيانة': return Colors.amber;
      case 'تم الإصلاح': return Colors.green;
      case 'بانتظار العميل': return Colors.teal;
      case 'مكتمل': return Colors.green.shade700;
      case 'مرفوض': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showEditDeviceDialog(BuildContext context, RepairDevice device) {
    final nameController = TextEditingController(text: device.customerName);
    final phoneController = TextEditingController(text: device.customerPhone);
    final modelController = TextEditingController(text: device.deviceModel);
    final notesController = TextEditingController(text: device.notes);
    final priceController = TextEditingController(text: device.estimatedPrice.toString());
    String selectedBrand = device.deviceBrand;
    String selectedCondition = device.deviceCondition;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الجهاز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل *')),
            const SizedBox(height: 8),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الموبيل *'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedBrand,
              items: Provider.of<RepairProvider>(context, listen: false).deviceBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => selectedBrand = val!,
              decoration: const InputDecoration(labelText: 'ماركة الجهاز *'),
            ),
            const SizedBox(height: 8),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'موديل الجهاز *')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCondition,
              items: Provider.of<RepairProvider>(context, listen: false).deviceConditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => selectedCondition = val!,
              decoration: const InputDecoration(labelText: 'حالة الجهاز *'),
            ),
            const SizedBox(height: 8),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر التقديري'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || phoneController.text.isEmpty || modelController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء الحقول المطلوبة')));
                return;
              }
              final updatedDevice = device.copyWith(
                customerName: nameController.text,
                customerPhone: phoneController.text,
                deviceBrand: selectedBrand,
                deviceModel: modelController.text,
                deviceCondition: selectedCondition,
                notes: notesController.text,
                estimatedPrice: double.tryParse(priceController.text) ?? 0,
              );
              Provider.of<RepairProvider>(context, listen: false).updateDevice(updatedDevice);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم التحديث')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RepairProvider>(context);
    final statusCounts = provider.getStatusCounts();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text('توزيع الأجهزة حسب الحالة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: provider.availableStatuses.length,
              itemBuilder: (ctx, index) {
                final status = provider.availableStatuses[index];
                final count = statusCounts[status] ?? 0;
                final color = _getStatusColor(status);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: color, child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(status),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$count جهاز', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () => _showDevicesByStatus(context, status),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الانتظار': return Colors.orange;
      case 'قيد الفحص': return Colors.blue;
      case 'في الانتظار (قطع غيار)': return Colors.purple;
      case 'قيد الصيانة': return Colors.amber;
      case 'تم الإصلاح': return Colors.green;
      case 'بانتظار العميل': return Colors.teal;
      case 'مكتمل': return Colors.green.shade700;
      case 'مرفوض': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showDevicesByStatus(BuildContext context, String status) {
    final provider = Provider.of<RepairProvider>(context, listen: false);
    final devices = provider.getDevicesByStatus(status);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('الأجهزة في حالة: $status'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: devices.isEmpty
              ? const Center(child: Text('لا توجد أجهزة'))
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (ctx, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: Text(device.id),
                      title: Text(device.customerName),
                      subtitle: Text('${device.deviceBrand} ${device.deviceModel}'),
                      trailing: Text(device.customerPhone),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RepairProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث باسم العميل، رقم الهاتف، الموديل، أو الكود',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFF16161D),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => provider.setSearchQuery(''))
                  : null,
            ),
            onChanged: provider.setSearchQuery,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.filteredDevices.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد نتائج'),
                  ]))
                : ListView.builder(
                    itemCount: provider.filteredDevices.length,
                    itemBuilder: (ctx, index) {
                      final device = provider.filteredDevices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(device.status),
                            child: Text(device.id.replaceAll('R', ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(device.customerName),
                          subtitle: Text('${device.deviceBrand} ${device.deviceModel}'),
                          trailing: Text(device.status, style: TextStyle(color: _getStatusColor(device.status), fontWeight: FontWeight.bold)),
                          onTap: () => _showDeviceDetails(context, device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الانتظار': return Colors.orange;
      case 'قيد الفحص': return Colors.blue;
      case 'في الانتظار (قطع غيار)': return Colors.purple;
      case 'قيد الصيانة': return Colors.amber;
      case 'تم الإصلاح': return Colors.green;
      case 'بانتظار العميل': return Colors.teal;
      case 'مكتمل': return Colors.green.shade700;
      case 'مرفوض': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showDeviceDetails(BuildContext context, RepairDevice device) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${device.customerName} - ${device.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('العميل', device.customerName),
            _buildDetailRow('الهاتف', device.customerPhone),
            _buildDetailRow('الماركة', device.deviceBrand),
            _buildDetailRow('الموديل', device.deviceModel),
            _buildDetailRow('الحالة', device.status),
            _buildDetailRow('حالة الجهاز', device.deviceCondition),
            _buildDetailRow('تاريخ الاستلام', '${device.receiveDate.day}/${device.receiveDate.month}/${device.receiveDate.year}'),
            if (device.notes.isNotEmpty) _buildDetailRow('ملاحظات', device.notes),
            _buildDetailRow('السعر التقديري', '${device.estimatedPrice} ج.م'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم إرسال الإشعار إلى ${device.customerPhone}'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('إرسال إشعار'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label + ':', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ============================================================
// 💳 القسم الرابع: المحافظ (جميع المعاملات تنقص الرصيد)
// ============================================================

class Wallet {
  String id;
  String customerName;
  String customerPhone;
  double dailyLimit;
  double monthlyLimit;
  double currentDailyTotal;
  double currentMonthlyTotal;
  DateTime lastTransactionDate;
  bool isActive;

  Wallet({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.dailyLimit,
    required this.monthlyLimit,
    this.currentDailyTotal = 0,
    this.currentMonthlyTotal = 0,
    required this.lastTransactionDate,
    this.isActive = true,
  });

  bool get isDailyLimitExceeded => currentDailyTotal >= dailyLimit;
  bool get isMonthlyLimitExceeded => currentMonthlyTotal >= monthlyLimit;
  double get remainingDailyLimit => dailyLimit - currentDailyTotal;
  double get remainingMonthlyLimit => monthlyLimit - currentMonthlyTotal;

  Wallet copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    double? dailyLimit,
    double? monthlyLimit,
    double? currentDailyTotal,
    double? currentMonthlyTotal,
    DateTime? lastTransactionDate,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentDailyTotal: currentDailyTotal ?? this.currentDailyTotal,
      currentMonthlyTotal: currentMonthlyTotal ?? this.currentMonthlyTotal,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String customerName;
  final String customerPhone;
  final double amount;
  final String message;
  final DateTime date;
  final double balanceAfter;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.message,
    required this.date,
    required this.balanceAfter,
  });
}

class WalletProvider extends ChangeNotifier {
  List<Wallet> _wallets = [];
  List<WalletTransaction> _transactions = [];
  String _searchQuery = '';

  List<Wallet> get wallets => _wallets;
  List<WalletTransaction> get transactions => _transactions;
  String get searchQuery => _searchQuery;

  double get totalBalance {
    double total = 0;
    for (var wallet in _wallets) { total += wallet.currentDailyTotal; }
    return total;
  }

  WalletProvider() {
    _wallets.addAll([
      Wallet(id: 'W001', customerName: 'أحمد محمد', customerPhone: '01012345678', dailyLimit: 10000, monthlyLimit: 100000, lastTransactionDate: DateTime.now()),
      Wallet(id: 'W002', customerName: 'سارة علي', customerPhone: '01123456789', dailyLimit: 5000, monthlyLimit: 50000, lastTransactionDate: DateTime.now().subtract(const Duration(days: 1))),
      Wallet(id: 'W003', customerName: 'محمد خالد', customerPhone: '01234567890', dailyLimit: 20000, monthlyLimit: 200000, lastTransactionDate: DateTime.now()),
    ]);

    _transactions.addAll([
      WalletTransaction(id: 'T001', walletId: 'W001', customerName: 'أحمد محمد', customerPhone: '01012345678', amount: 5000, message: 'خصم مبلغ', date: DateTime.now().subtract(const Duration(hours: 2)), balanceAfter: 5000),
      WalletTransaction(id: 'T002', walletId: 'W002', customerName: 'سارة علي', customerPhone: '01123456789', amount: 2000, message: 'خصم مبلغ', date: DateTime.now().subtract(const Duration(hours: 1)), balanceAfter: 3000),
    ]);
  }

  void addWallet(Wallet wallet) { _wallets.add(wallet); notifyListeners(); }
  void updateWallet(Wallet updatedWallet) {
    final index = _wallets.indexWhere((w) => w.id == updatedWallet.id);
    if (index != -1) { _wallets[index] = updatedWallet; notifyListeners(); }
  }
  void deleteWallet(String id) { _wallets.removeWhere((w) => w.id == id); notifyListeners(); }

  // 🔥 جميع المعاملات تنقص الرصيد (مفيش إضافة خالص)
  void addTransaction(WalletTransaction transaction) {
    _transactions.add(transaction);
    final walletIndex = _wallets.indexWhere((w) => w.id == transaction.walletId);
    if (walletIndex != -1) {
      _wallets[walletIndex].currentDailyTotal -= transaction.amount;
      _wallets[walletIndex].currentMonthlyTotal -= transaction.amount;
      _wallets[walletIndex].lastTransactionDate = transaction.date;
    }
    notifyListeners();
  }

  void deleteTransaction(String id) {
    final transaction = _transactions.firstWhere((t) => t.id == id);
    _transactions.removeWhere((t) => t.id == id);
    final walletIndex = _wallets.indexWhere((w) => w.id == transaction.walletId);
    if (walletIndex != -1) {
      _wallets[walletIndex].currentDailyTotal += transaction.amount;
      _wallets[walletIndex].currentMonthlyTotal += transaction.amount;
    }
    notifyListeners();
  }

  String generateWalletId() { final count = _wallets.length + 1; return 'W${count.toString().padLeft(3, '0')}'; }
  String generateTransactionId() { final count = _transactions.length + 1; return 'T${count.toString().padLeft(3, '0')}'; }

  List<WalletTransaction> get filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    final query = _searchQuery.toLowerCase();
    return _transactions.where((t) =>
      t.customerName.toLowerCase().contains(query) ||
      t.customerPhone.contains(query) ||
      t.id.toLowerCase().contains(query)
    ).toList();
  }
  void setSearchQuery(String query) { _searchQuery = query; notifyListeners(); }

  bool checkDailyLimit(String walletId, double amount) {
    final wallet = _wallets.firstWhere((w) => w.id == walletId);
    return wallet.currentDailyTotal - amount >= 0;
  }
  bool checkMonthlyLimit(String walletId, double amount) {
    final wallet = _wallets.firstWhere((w) => w.id == walletId);
    return wallet.currentMonthlyTotal - amount >= 0;
  }

  Map<String, dynamic> parseMessage(String message) {
    Map<String, dynamic> result = {};
    RegExp amountRegExp = RegExp(r'(\d+[.,]?\d*)\s*(جنيه|ج\.م)');
    var amountMatch = amountRegExp.firstMatch(message);
    if (amountMatch != null) {
      result['amount'] = double.parse(amountMatch.group(1)!.replaceAll(',', '.'));
    }
    RegExp phoneRegExp = RegExp(r'(01[0-9]{9})');
    var phoneMatch = phoneRegExp.firstMatch(message);
    if (phoneMatch != null) { result['phone'] = phoneMatch.group(0); }
    RegExp nameRegExp = RegExp(r'(?:الى|من|لـ|ل)(?:\s*)([^\s]+(?:\s+[^\s]+){0,2})');
    var nameMatch = nameRegExp.firstMatch(message);
    if (nameMatch != null) { result['name'] = nameMatch.group(1)?.trim(); }
    return result;
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحافظ الإلكترونية'),
          bottom: const TabBar(tabs: [Tab(text: 'المحافظ'), Tab(text: 'المعاملات'), Tab(text: 'الأرشيف')]),
        ),
        body: const TabBarView(children: [WalletsTab(), TransactionsTab(), ArchiveTab()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddWalletDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final dailyLimitController = TextEditingController();
    final monthlyLimitController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة محفظة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل *')),
            const SizedBox(height: 8),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الموبيل *'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            TextField(controller: dailyLimitController, decoration: const InputDecoration(labelText: 'الميت اليومي *', hintText: 'مثال: 10000'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: monthlyLimitController, decoration: const InputDecoration(labelText: 'الميت الشهري *', hintText: 'مثال: 100000'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || phoneController.text.isEmpty ||
                  dailyLimitController.text.isEmpty || monthlyLimitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء جميع الحقول')));
                return;
              }
              final provider = Provider.of<WalletProvider>(context, listen: false);
              final newId = provider.generateWalletId();
              provider.addWallet(Wallet(
                id: newId,
                customerName: nameController.text,
                customerPhone: phoneController.text,
                dailyLimit: double.parse(dailyLimitController.text),
                monthlyLimit: double.parse(monthlyLimitController.text),
                lastTransactionDate: DateTime.now(),
              ));
              Provider.of<CustomersProvider>(context, listen: false).addCustomer(
                name: nameController.text,
                phone: phoneController.text,
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم إضافة المحفظة - الكود: $newId'), backgroundColor: Colors.green),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class WalletsTab extends StatelessWidget {
  const WalletsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletProvider>(context);
    return provider.wallets.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wallet, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد محافظ'),
            Text('اضغط على + للإضافة'),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.wallets.length,
            itemBuilder: (ctx, index) {
              final wallet = provider.wallets[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: wallet.isActive ? Colors.green : Colors.red,
                    child: Text(wallet.id.replaceAll('W', ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(wallet.customerName),
                  subtitle: Text(wallet.customerPhone),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('الكود', wallet.id),
                          _buildInfoRow('العميل', wallet.customerName),
                          _buildInfoRow('الهاتف', wallet.customerPhone),
                          _buildInfoRow('الميت اليومي', '${wallet.dailyLimit.toStringAsFixed(2)} ج.م'),
                          _buildInfoRow('الميت الشهري', '${wallet.monthlyLimit.toStringAsFixed(2)} ج.م'),
                          _buildInfoRow('الرصيد المتبقي', '${wallet.currentDailyTotal.toStringAsFixed(2)} ج.م'),
                          _buildInfoRow('المتبقي اليومي', '${wallet.remainingDailyLimit.toStringAsFixed(2)} ج.م'),
                          _buildInfoRow('المتبقي الشهري', '${wallet.remainingMonthlyLimit.toStringAsFixed(2)} ج.م'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showAddTransactionDialog(context, wallet),
                                icon: const Icon(Icons.remove_circle),
                                label: const Text('خصم'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showParseMessageDialog(context, wallet),
                                icon: const Icon(Icons.text_snippet),
                                label: const Text('قراءة رسالة'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                              ),
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditWalletDialog(context, wallet)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: Text('هل أنت متأكد من حذف محفظة ${wallet.customerName}؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                                      ElevatedButton(
                                        onPressed: () {
                                          provider.deleteWallet(wallet.id);
                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المحفظة')));
                                        },
                                        child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label + ':', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, Wallet wallet) {
    final amountController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('خصم من محفظة ${wallet.customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ *'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: messageController, decoration: const InputDecoration(labelText: 'الرسالة'), maxLines: 2),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الرصيد الحالي: ${wallet.currentDailyTotal.toStringAsFixed(2)} ج.م'),
                  Text('الميت اليومي المتبقي: ${wallet.remainingDailyLimit.toStringAsFixed(2)} ج.م'),
                  Text('الميت الشهري المتبقي: ${wallet.remainingMonthlyLimit.toStringAsFixed(2)} ج.م'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى إدخال المبلغ'), backgroundColor: Colors.orange));
                return;
              }
              final amount = double.parse(amountController.text);
              final provider = Provider.of<WalletProvider>(context, listen: false);
              if (!provider.checkDailyLimit(wallet.id, amount)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ الرصيد غير كافٍ للميت اليومي'), backgroundColor: Colors.orange));
                return;
              }
              if (!provider.checkMonthlyLimit(wallet.id, amount)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ الرصيد غير كافٍ للميت الشهري'), backgroundColor: Colors.orange));
                return;
              }
              final newId = provider.generateTransactionId();
              provider.addTransaction(WalletTransaction(
                id: newId,
                walletId: wallet.id,
                customerName: wallet.customerName,
                customerPhone: wallet.customerPhone,
                amount: amount,
                message: messageController.text.isNotEmpty ? messageController.text : 'خصم مبلغ',
                date: DateTime.now(),
                balanceAfter: wallet.currentDailyTotal - amount,
              ));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم خصم ${amount.toStringAsFixed(2)} ج.م'), backgroundColor: Colors.green),
              );
            },
            child: const Text('تنفيذ الخصم'),
          ),
        ],
      ),
    );
  }

  void _showParseMessageDialog(BuildContext context, Wallet wallet) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('قراءة رسالة - ${wallet.customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('انسخ رسالة التحويل/الاستلام هنا:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
              child: TextField(
                controller: messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'مثال:\nاستلام 5000 جنيه من أحمد محمد 01012345678\nأو\nتحويل 2000 ج.م إلى سارة علي 01123456789',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: const Text('💡 سيتم استخراج: المبلغ، اسم العميل، رقم الهاتف تلقائياً', style: TextStyle(fontSize: 12, color: Colors.blue)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () {
              if (messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى كتابة الرسالة')));
                return;
              }
              final provider = Provider.of<WalletProvider>(context, listen: false);
              final parsedData = provider.parseMessage(messageController.text);
              if (parsedData['amount'] == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ لم يتم العثور على مبلغ'), backgroundColor: Colors.orange));
                return;
              }
              final amount = parsedData['amount'] as double;
              if (!provider.checkDailyLimit(wallet.id, amount)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ الرصيد غير كافٍ'), backgroundColor: Colors.orange));
                return;
              }
              final newId = provider.generateTransactionId();
              provider.addTransaction(WalletTransaction(
                id: newId,
                walletId: wallet.id,
                customerName: parsedData['name'] ?? wallet.customerName,
                customerPhone: parsedData['phone'] ?? wallet.customerPhone,
                amount: amount,
                message: messageController.text,
                date: DateTime.now(),
                balanceAfter: wallet.currentDailyTotal - amount,
              ));
              Provider.of<CustomersProvider>(context, listen: false).addCustomer(
                name: parsedData['name'] ?? wallet.customerName,
                phone: parsedData['phone'] ?? wallet.customerPhone,
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ تم خصم ${amount.toStringAsFixed(2)} ج.م من الرسالة'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('تنفيذ الخصم'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showEditWalletDialog(BuildContext context, Wallet wallet) {
    final nameController = TextEditingController(text: wallet.customerName);
    final phoneController = TextEditingController(text: wallet.customerPhone);
    final dailyLimitController = TextEditingController(text: wallet.dailyLimit.toString());
    final monthlyLimitController = TextEditingController(text: wallet.monthlyLimit.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل المحفظة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم العميل *')),
            const SizedBox(height: 8),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الموبيل *'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            TextField(controller: dailyLimitController, decoration: const InputDecoration(labelText: 'الميت اليومي'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: monthlyLimitController, decoration: const InputDecoration(labelText: 'الميت الشهري'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء الحقول المطلوبة')));
                return;
              }
              final updatedWallet = wallet.copyWith(
                customerName: nameController.text,
                customerPhone: phoneController.text,
                dailyLimit: double.tryParse(dailyLimitController.text) ?? wallet.dailyLimit,
                monthlyLimit: double.tryParse(monthlyLimitController.text) ?? wallet.monthlyLimit,
              );
              Provider.of<WalletProvider>(context, listen: false).updateWallet(updatedWallet);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم التحديث')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletProvider>(context);
    return provider.transactions.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.swap_horiz, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد معاملات'),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.transactions.length,
            itemBuilder: (ctx, index) {
              final transaction = provider.transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.arrow_upward, color: Colors.white)),
                  title: Text(transaction.customerName),
                  subtitle: Text(transaction.message),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('- ${transaction.amount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      Text('الكود: ${transaction.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => _showTransactionDetails(context, transaction),
                ),
              );
            },
          );
  }

  void _showTransactionDetails(BuildContext context, WalletTransaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تفاصيل المعاملة - ${transaction.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('العميل', transaction.customerName),
            _buildDetailRow('الهاتف', transaction.customerPhone),
            _buildDetailRow('المبلغ', '- ${transaction.amount.toStringAsFixed(2)} ج.م'),
            _buildDetailRow('الرسالة', transaction.message),
            _buildDetailRow('التاريخ', '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}'),
            _buildDetailRow('الرصيد بعد', '${transaction.balanceAfter.toStringAsFixed(2)} ج.م'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<WalletProvider>(context, listen: false).deleteTransaction(transaction.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المعاملة'), backgroundColor: Colors.red));
            },
            icon: const Icon(Icons.delete),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label + ':', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class ArchiveTab extends StatelessWidget {
  const ArchiveTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث برقم الهاتف أو اسم العميل أو الكود',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFF16161D),
            ),
            onChanged: provider.setSearchQuery,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.filteredTransactions.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.archive, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد معاملات'),
                  ]))
                : ListView.builder(
                    itemCount: provider.filteredTransactions.length,
                    itemBuilder: (ctx, index) {
                      final transaction = provider.filteredTransactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(transaction.customerName),
                          subtitle: Text('${transaction.customerPhone} - ${transaction.id}'),
                          trailing: Text('- ${transaction.amount.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 👥 القسم الخامس: العملاء (مع إرسال رسائل جماعية لجميع الأرقام)
// ============================================================

class Customer {
  final String id;
  final String name;
  final String phone;
  final DateTime addedDate;
  Customer({required this.id, required this.name, required this.phone, required this.addedDate});
}

class CustomersProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  String _searchQuery = '';
  List<Customer> get customers => _customers;
  String get searchQuery => _searchQuery;

  CustomersProvider() {
    _customers.addAll([
      Customer(id: 'C001', name: 'أحمد محمد', phone: '01012345678', addedDate: DateTime.now().subtract(const Duration(days: 10))),
      Customer(id: 'C002', name: 'سارة علي', phone: '01123456789', addedDate: DateTime.now().subtract(const Duration(days: 5))),
      Customer(id: 'C003', name: 'محمد خالد', phone: '01234567890', addedDate: DateTime.now().subtract(const Duration(days: 3))),
    ]);
  }

  void addCustomer({required String name, required String phone}) {
    if (name.isEmpty || phone.isEmpty) return;
    final exists = _customers.any((c) => c.phone == phone);
    if (!exists) {
      _customers.add(Customer(id: 'C${(_customers.length + 1).toString().padLeft(3, '0')}', name: name, phone: phone, addedDate: DateTime.now()));
      notifyListeners();
    }
  }

  void deleteCustomer(String id) { _customers.removeWhere((c) => c.id == id); notifyListeners(); }

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query)).toList();
  }

  void setSearchQuery(String query) { _searchQuery = query; notifyListeners(); }
  List<String> getAllPhones() { return _customers.map((c) => c.phone).toList(); }
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _selectedPhones = [];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomersProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العملاء'),
          bottom: const TabBar(tabs: [Tab(text: 'قائمة العملاء'), Tab(text: 'إرسال رسائل')]),
        ),
        body: TabBarView(
          children: [
            // قائمة العملاء
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم العميل أو رقم الهاتف',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF16161D),
                    ),
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                Expanded(
                  child: provider.filteredCustomers.isEmpty
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا يوجد عملاء'),
                        ]))
                      : ListView.builder(
                          itemCount: provider.filteredCustomers.length,
                          itemBuilder: (ctx, index) {
                            final customer = provider.filteredCustomers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(customer.name[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(customer.name),
                                subtitle: Text(customer.phone),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('تأكيد الحذف'),
                                        content: Text('هل أنت متأكد من حذف ${customer.name}؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            onPressed: () {
                                              provider.deleteCustomer(customer.id);
                                              Navigator.pop(dialogContext);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف العميل')));
                                            },
                                            child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // إرسال رسائل جماعية - 🔥 إرسال لكل الأرقام المختارة
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر العملاء لإرسال الرسالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: provider.customers.isEmpty
                        ? const Center(child: Text('لا يوجد عملاء'))
                        : ListView.builder(
                            itemCount: provider.customers.length,
                            itemBuilder: (ctx, index) {
                              final customer = provider.customers[index];
                              final isSelected = _selectedPhones.contains(customer.phone);
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPhones.remove(customer.phone);
                                    } else {
                                      _selectedPhones.add(customer.phone);
                                    }
                                  });
                                },
                                title: Text(customer.name),
                                subtitle: Text(customer.phone),
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPhones.clear();
                              _selectedPhones.addAll(provider.getAllPhones());
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text('تحديد الكل'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() { _selectedPhones.clear(); });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('إلغاء الكل'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('نص الرسالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'أدخل نص الرسالة...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedPhones.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: Wrap(
                        spacing: 4,
                        children: _selectedPhones.map((phone) => Chip(
                          label: Text(phone),
                          onDeleted: () { setState(() { _selectedPhones.remove(phone); }); },
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedPhones.isEmpty || _messageController.text.isEmpty
                          ? null
                          : () {
                              // 🔥 إرسال الرسالة لكل الأرقام المختارة (جميع الأرقام)
                              for (var phone in _selectedPhones) {
                                debugPrint('📨 إرسال إلى $phone: ${_messageController.text}');
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('✅ تم إرسال الرسالة إلى ${_selectedPhones.length} عميل'), backgroundColor: Colors.green),
                              );
                              setState(() {
                                _selectedPhones.clear();
                                _messageController.clear();
                              });
                            },
                      icon: const Icon(Icons.send),
                      label: Text('إرسال إلى ${_selectedPhones.length} عميل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💰 القسم السادس: المصروفات
// ============================================================

class Expense {
  String id;
  String category;
  double amount;
  String description;
  DateTime date;
  Expense({required this.id, required this.category, required this.amount, required this.description, required this.date});
}

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<String> _categories = ['إيجار', 'مرتبات', 'كهرباء', 'مياه', 'شراء بضاعة', 'أخرى'];
  List<Expense> get expenses => _expenses;
  List<String> get categories => _categories;
  double get totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);

  ExpenseProvider() {
    _expenses.addAll([
      Expense(id: '1', category: 'إيجار', amount: 2000, description: 'إيجار المحل', date: DateTime.now()),
      Expense(id: '2', category: 'كهرباء', amount: 350, description: 'فاتورة الكهرباء', date: DateTime.now().subtract(const Duration(days: 1))),
    ]);
  }

  void addExpense(Expense expense) { _expenses.add(expense); notifyListeners(); }
  void deleteExpense(String id) { _expenses.removeWhere((e) => e.id == id); notifyListeners(); }
  void addCategory(String category) { if (!_categories.contains(category)) { _categories.add(category); notifyListeners(); } }
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        actions: [
          Consumer<ExpenseProvider>(
            builder: (_, provider, __) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                child: Text('الإجمالي: ${provider.totalExpenses.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (_, provider, __) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.expenses.length,
          itemBuilder: (ctx, index) {
            final expense = provider.expenses[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Text(expense.category[0], style: const TextStyle(color: Colors.red)),
                ),
                title: Text(expense.category),
                subtitle: Text(expense.description),
                trailing: Text('${expense.amount.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: () => _showExpenseDetails(context, expense),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'نوع المصروف *')),
            const SizedBox(height: 8),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ *'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'البيان')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (categoryController.text.isEmpty || amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء الحقول المطلوبة')));
                return;
              }
              final provider = Provider.of<ExpenseProvider>(context, listen: false);
              provider.addExpense(Expense(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                category: categoryController.text,
                amount: double.parse(amountController.text),
                description: descController.text,
                date: DateTime.now(),
              ));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم الإضافة')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(expense.category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ: ${expense.amount.toStringAsFixed(2)} ج.م'),
            Text('البيان: ${expense.description}'),
            Text('التاريخ: ${expense.date.day}/${expense.date.month}/${expense.date.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<ExpenseProvider>(context, listen: false).deleteExpense(expense.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المصروف')));
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}

// ============================================================
// 📅 القسم السابع: اليومية
// ============================================================

class DailyTransaction {
  final String id;
  final String type;
  final String description;
  final double amount;
  final DateTime date;
  final String? customerName;
  DailyTransaction({required this.id, required this.type, required this.description, required this.amount, required this.date, this.customerName});
}

class DailyProvider extends ChangeNotifier {
  List<DailyTransaction> _transactions = [];
  List<DailyTransaction> get transactions => _transactions;
  double get totalSales => _transactions.where((t) => t.type == 'sale').fold(0, (sum, t) => sum + t.amount);
  double get totalExpenses => _transactions.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount);
  double get netProfit => totalSales - totalExpenses;

  DailyProvider() {
    _transactions.addAll([
      DailyTransaction(id: '1', type: 'sale', description: 'بيع شاشة آيفون 13', amount: 850, date: DateTime.now(), customerName: 'أحمد'),
      DailyTransaction(id: '2', type: 'sale', description: 'بيع بطارية سامسونج', amount: 350, date: DateTime.now(), customerName: 'محمد'),
      DailyTransaction(id: '3', type: 'expense', description: 'شراء بضاعة', amount: 500, date: DateTime.now()),
    ]);
  }

  void addTransaction(DailyTransaction transaction) { _transactions.add(transaction); notifyListeners(); }
}

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DailyProvider>(
        builder: (_, provider, __) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('المبيعات', provider.totalSales, Colors.green),
                  _buildStatCard('المصروفات', provider.totalExpenses, Colors.red),
                  _buildStatCard('صافي الربح', provider.netProfit, Colors.blue),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: provider.transactions.length,
                itemBuilder: (ctx, index) {
                  final transaction = provider.transactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(transaction.type == 'sale' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: transaction.type == 'sale' ? Colors.green : Colors.red),
                      title: Text(transaction.description),
                      subtitle: transaction.customerName != null ? Text('العميل: ${transaction.customerName}') : null,
                      trailing: Text('${transaction.amount.toStringAsFixed(2)} ج.م',
                          style: TextStyle(color: transaction.type == 'sale' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('${amount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'sale';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة معاملة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sale', label: Text('بيع'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'expense', label: Text('مصروف'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {type},
              onSelectionChanged: (Set<String> newSelection) { type = newSelection.first; },
            ),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'البيان *')),
            const SizedBox(height: 8),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ *'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isEmpty || amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى ملء الحقول')));
                return;
              }
              final provider = Provider.of<DailyProvider>(context, listen: false);
              provider.addTransaction(DailyTransaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: type,
                description: descController.text,
                amount: double.parse(amountController.text),
                date: DateTime.now(),
              ));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم الإضافة')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ⚙️ القسم الثامن: الإعدادات
// ============================================================

class SettingsProvider extends ChangeNotifier {
  String _whatsappNumber = '';
  String _whatsappMessage = '''📱 *شركة تاجر - فاتورة*

👤 العميل: {customerName}
📞 الهاتف: {customerPhone}

{items}

💰 *الإجمالي: {total} ج.م*

🙏 شكراً لتسوقكم معنا''';

  bool _autoSend = true;
  String get whatsappNumber => _whatsappNumber;
  String get whatsappMessage => _whatsappMessage;
  bool get autoSend => _autoSend;

  void setWhatsappNumber(String number) { _whatsappNumber = number; notifyListeners(); }
  void setWhatsappMessage(String message) { _whatsappMessage = message; notifyListeners(); }
  void toggleAutoSend(bool value) { _autoSend = value; notifyListeners(); }

  String buildMessage({
    required String customerName,
    required String customerPhone,
    required List<Product> items,
    required double total,
  }) {
    String message = _whatsappMessage;
    message = message.replaceAll('{customerName}', customerName.isNotEmpty ? customerName : 'غير محدد');
    message = message.replaceAll('{customerPhone}', customerPhone.isNotEmpty ? customerPhone : 'غير محدد');
    message = message.replaceAll('{total}', total.toStringAsFixed(2));
    String itemsText = '';
    for (var item in items) {
      itemsText += '• ${item.name}  ×${item.quantity}  = ${(item.price * item.quantity).toStringAsFixed(2)} ج.م\n';
    }
    message = message.replaceAll('{items}', itemsText);
    return message;
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SettingsBody(),
    );
  }
}

class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.chat, color: Colors.green[700], size: 28),
                  const SizedBox(width: 10),
                  Text('إعدادات واتساب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
                ]),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'رقم واتساب الشركة',
                    hintText: 'مثال: 01012345678',
                    prefixIcon: const Icon(Icons.phone, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: settings.setWhatsappNumber,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Switch(value: settings.autoSend, onChanged: settings.toggleAutoSend, activeColor: Colors.green),
                  const Text('الإرسال التلقائي', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  if (settings.autoSend) Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                ]),
                const SizedBox(height: 12),
                const Text('نص الرسالة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'أدخل نص الرسالة...\nاستخدم {customerName} لاسم العميل\nاستخدم {customerPhone} لرقم العميل\nاستخدم {items} لقائمة المنتجات\nاستخدم {total} للإجمالي',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: settings.setWhatsappMessage,
                    controller: TextEditingController(text: settings.whatsappMessage),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المتغيرات المتاحة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: const [
                          Chip(label: Text('{customerName}'), backgroundColor: Colors.white),
                          Chip(label: Text('{customerPhone}'), backgroundColor: Colors.white),
                          Chip(label: Text('{items}'), backgroundColor: Colors.white),
                          Chip(label: Text('{total}'), backgroundColor: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showPreviewDialog(context, settings),
                  icon: const Icon(Icons.preview),
                  label: const Text('معاينة الرسالة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 10),
                  Text('معلومات التطبيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                ]),
                const SizedBox(height: 12),
                const ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text('نظام إدارة المبيعات'),
                  subtitle: Text('شركة تاجر للصيانة والمبيعات'),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('الإصدار'),
                  subtitle: Text('1.0.0'),
                ),
                const ListTile(
                  leading: Icon(Icons.build),
                  title: Text('المطور'),
                  subtitle: Text('تم التطوير بواسطة Flutter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, SettingsProvider settings) {
    final List<Product> previewItems = [
      Product(id: '1', name: 'شاشة آيفون 13', price: 850, imageUrl: '', quantity: 2),
      Product(id: '2', name: 'كابل شحن', price: 120, imageUrl: '', quantity: 1),
    ];
    String message = settings.buildMessage(
      customerName: 'أحمد محمد',
      customerPhone: '01012345678',
      items: previewItems,
      total: 1820,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('معاينة الرسالة'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(message, style: const TextStyle(fontSize: 14), textDirection: TextDirection.rtl),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }
}