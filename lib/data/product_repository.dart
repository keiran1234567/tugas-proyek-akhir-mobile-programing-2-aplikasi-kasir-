import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository._();

  static final instance = ProductRepository._();

  Database? _database;
  static const _webProductsKey = 'warmin_products';

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final databasePath = path.join(
      await getDatabasesPath(),
      'warmin_products.db',
    );
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price INTEGER NOT NULL,
            stock INTEGER NOT NULL
          )
        ''');
        final batch = database.batch();
        for (final product in _sampleProducts) {
          batch.insert('products', product.toMap());
        }
        await batch.commit(noResult: true);
      },
    );
    return _database!;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getString(_webProductsKey) == null) {
        await _saveWebProducts([
          for (var index = 0; index < _sampleProducts.length; index++)
            Product(
              id: index + 1,
              name: _sampleProducts[index].name,
              category: _sampleProducts[index].category,
              price: _sampleProducts[index].price,
              stock: _sampleProducts[index].stock,
            ),
        ]);
      }
      return;
    }
    await _db;
  }

  Future<List<Product>> getProducts() async {
    if (kIsWeb) {
      final products = await _getWebProducts();
      products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return products;
    }
    final rows = await (await _db).query('products', orderBy: 'name COLLATE NOCASE');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> createProduct(Product product) async {
    if (kIsWeb) {
      final products = await _getWebProducts();
      final nextId = products.fold<int>(
            0,
            (largestId, current) => current.id! > largestId ? current.id! : largestId,
          ) +
          1;
      products.add(
        Product(
          id: nextId,
          name: product.name,
          category: product.category,
          price: product.price,
          stock: product.stock,
        ),
      );
      await _saveWebProducts(products);
      return;
    }
    await (await _db).insert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final id = product.id;
    if (id == null) {
      throw ArgumentError.value(product, 'product', 'Product id is required.');
    }
    if (kIsWeb) {
      final products = await _getWebProducts();
      final index = products.indexWhere((current) => current.id == id);
      if (index == -1) {
        throw StateError('Produk yang akan diubah tidak ditemukan.');
      }
      products[index] = product;
      await _saveWebProducts(products);
      return;
    }
    final changedRows = await (await _db).update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changedRows != 1) {
      throw StateError('Produk yang akan diubah tidak ditemukan.');
    }
  }

  Future<void> deleteProduct(int id) async {
    if (kIsWeb) {
      final products = await _getWebProducts();
      final initialLength = products.length;
      products.removeWhere((product) => product.id == id);
      if (products.length == initialLength) {
        throw StateError('Produk yang akan dihapus tidak ditemukan.');
      }
      await _saveWebProducts(products);
      return;
    }
    final changedRows = await (await _db).delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changedRows != 1) {
      throw StateError('Produk yang akan dihapus tidak ditemukan.');
    }
  }

  Future<List<Product>> _getWebProducts() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedProducts = preferences.getString(_webProductsKey);
    if (encodedProducts == null) return [];
    final decoded = jsonDecode(encodedProducts) as List<dynamic>;
    return decoded
        .map(
          (item) => Product.fromMap(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> _saveWebProducts(List<Product> products) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedProducts = jsonEncode([
      for (final product in products)
        {
          'id': product.id,
          ...product.toMap(),
        },
    ]);
    final saved = await preferences.setString(_webProductsKey, encodedProducts);
    if (!saved) {
      throw StateError('Data produk gagal disimpan di penyimpanan browser.');
    }
  }
}

const _sampleProducts = [
  Product(name: 'Kopi Susu', category: 'Minuman', price: 18000, stock: 24),
  Product(name: 'Roti Bakar Cokelat', category: 'Makanan', price: 15000, stock: 12),
  Product(name: 'Air Mineral', category: 'Minuman', price: 5000, stock: 36),
  Product(name: 'Kentang Goreng', category: 'Camilan', price: 16000, stock: 8),
];
