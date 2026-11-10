import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/product_repository.dart';
import 'models/product.dart';
import 'screens/login_screen.dart';
import 'screens/products_screen.dart';

void main() {
  runApp(const WarminApp());
}

class WarminApp extends StatelessWidget {
  const WarminApp({super.key});

  static const _green = Color(0xFF245B45);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warmin Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          primary: _green,
          surface: const Color(0xFFF8F8F4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8F4),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E9E3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E9E3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
        ),
      ),
      home: const KasirApp(),
    );
  }
}

class KasirApp extends StatefulWidget {
  const KasirApp({super.key});

  @override
  State<KasirApp> createState() => _KasirAppState();
}

class _KasirAppState extends State<KasirApp> {
  bool _isReady = false;
  bool _isLoggedIn = false;
  Object? _startupError;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await ProductRepository.instance.initialize();
      final preferences = await SharedPreferences.getInstance();
      final isLoggedIn = preferences.getBool('warmin_logged_in') ?? false;
      final products = isLoggedIn
          ? await ProductRepository.instance.getProducts()
          : <Product>[];
      if (!mounted) return;
      setState(() {
        _isLoggedIn = isLoggedIn;
        _products = products;
        _isReady = true;
        _startupError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startupError = error;
        _isReady = true;
      });
    }
  }

  Future<bool> _login(String username, String password) async {
    if (username.trim().toLowerCase() != 'admin' ||
        password != 'warmin123') {
      return false;
    }
    final products = await ProductRepository.instance.getProducts();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('warmin_logged_in', true);
    if (!mounted) return true;
    setState(() {
      _isLoggedIn = true;
      _products = products;
    });
    return true;
  }

  Future<void> _logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('warmin_logged_in');
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
    });
  }

  Future<void> _createProduct(Product product) async {
    await ProductRepository.instance.createProduct(product);
    await _refreshProducts();
  }

  Future<void> _updateProduct(Product product) async {
    await ProductRepository.instance.updateProduct(product);
    await _refreshProducts();
  }

  Future<void> _deleteProduct(int id) async {
    await ProductRepository.instance.deleteProduct(id);
    await _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    final products = await ProductRepository.instance.getProducts();
    if (!mounted) return;
    setState(() => _products = products);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_startupError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Aplikasi gagal memuat data.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Detail: $_startupError', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isReady = false;
                      _startupError = null;
                    });
                    _initialize();
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _login);
    }

    return ProductsScreen(
      products: _products,
      onCreate: _createProduct,
      onUpdate: _updateProduct,
      onDelete: _deleteProduct,
      onLogout: _logout,
    );
  }
}
