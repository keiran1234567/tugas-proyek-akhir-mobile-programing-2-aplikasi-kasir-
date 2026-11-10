import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    super.key,
    required this.products,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onLogout,
  });

  final List<Product> products;
  final Future<void> Function(Product product) onCreate;
  final Future<void> Function(Product product) onUpdate;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function() onLogout;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.products;
    return widget.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _showProductForm({Product? product}) async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormSheet(product: product),
    );
    if (result == null || !mounted) return;
    try {
      if (product == null) {
        await widget.onCreate(result);
      } else {
        await widget.onUpdate(result);
      }
      if (!mounted) return;
      _showMessage(product == null ? 'Produk berhasil ditambahkan.' : 'Produk berhasil diperbarui.');
    } catch (error) {
      if (mounted) _showMessage('Gagal menyimpan produk: $error', isError: true);
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Produk "${product.name}" akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB63B32),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || product.id == null) return;
    try {
      await widget.onDelete(product.id!);
      if (mounted) _showMessage('Produk berhasil dihapus.');
    } catch (error) {
      if (mounted) _showMessage('Gagal menghapus produk: $error', isError: true);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.onLogout();
    } catch (error) {
      if (mounted) _showMessage('Gagal logout: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? const Color(0xFFB63B32) : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final lowStockCount = widget.products.where((product) => product.stock < 10).length;
    final totalStock = widget.products.fold<int>(0, (total, product) => total + product.stock);
    final pageWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = pageWidth > 1000 ? 920.0 : pageWidth;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F4),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF245B45),
                size: 23,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warmin',
                  style: TextStyle(
                    color: Color(0xFF202720),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'KASIR • INVENTARIS',
                  style: TextStyle(
                    color: Color(0xFF858C83),
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            color: const Color(0xFF667067),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Text(
                  'Ruang kendali',
                  style: TextStyle(
                    color: Color(0xFF202720),
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Kelola produk tokomu dengan praktis.',
                  style: TextStyle(
                    color: Color(0xFF767E75),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryCard(
                          width: cardWidth,
                          icon: Icons.inventory_2_outlined,
                          label: 'Total produk',
                          value: '${widget.products.length}',
                          tint: const Color(0xFFE8F1EA),
                          iconColor: const Color(0xFF245B45),
                        ),
                        _SummaryCard(
                          width: cardWidth,
                          icon: Icons.stacked_bar_chart_rounded,
                          label: 'Total stok',
                          value: '$totalStock item',
                          tint: const Color(0xFFF5EEDF),
                          iconColor: const Color(0xFF9A6E22),
                        ),
                        _SummaryCard(
                          width: cardWidth,
                          icon: Icons.notifications_active_outlined,
                          label: 'Stok menipis',
                          value: '$lowStockCount produk',
                          tint: const Color(0xFFF7E9E5),
                          iconColor: const Color(0xFFB65A42),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Daftar produk',
                        style: TextStyle(
                          color: Color(0xFF202720),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showProductForm(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Tambah'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF245B45),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau kategori produk...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                if (products.isEmpty)
                  _EmptyProducts(
                    hasProducts: widget.products.isNotEmpty,
                    onAdd: () => _showProductForm(),
                  )
                else
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProductCard(
                        product: product,
                        onEdit: () => _showProductForm(product: product),
                        onDelete: () => _confirmDelete(product),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.iconColor,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 21, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF7C847B), fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF263129),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock < 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1EA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _categoryIcon(product.category),
              color: const Color(0xFF245B45),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF273129),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.category,
                  style: const TextStyle(
                    color: Color(0xFF838A81),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 9,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _formatRupiah(product.price),
                      style: const TextStyle(
                        color: Color(0xFF245B45),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? const Color(0xFFFFF1E8)
                            : const Color(0xFFF0F3EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stok ${product.stock}',
                        style: TextStyle(
                          color: isLowStock
                              ? const Color(0xFFB65A42)
                              : const Color(0xFF657066),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Aksi produk',
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Ubah'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: Color(0xFFB63B32)),
                  title: Text('Hapus', style: TextStyle(color: Color(0xFFB63B32))),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF737A72)),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.hasProducts, required this.onAdd});

  final bool hasProducts;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECE7)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: Color(0xFF91A195),
          ),
          const SizedBox(height: 12),
          Text(
            hasProducts ? 'Produk tidak ditemukan' : 'Belum ada produk',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF303A32),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasProducts
                ? 'Coba kata kunci pencarian yang lain.'
                : 'Tambahkan produk pertama untuk memulai.',
            style: const TextStyle(color: Color(0xFF828A81), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (!hasProducts) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah produk'),
            ),
          ],
        ],
      ),
    );
  }
}

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    _stockController = TextEditingController(
      text: product == null ? '' : product.stock.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi.';
    return null;
  }

  String? _nonNegativeInteger(String? value, String label) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return '$label harus berupa angka bulat.';
    if (number < 0) return '$label tidak boleh kurang dari 0.';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        price: int.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F8F4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DAD3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Ubah produk' : 'Tambah produk',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202720),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing
                      ? 'Perbarui informasi produk di bawah ini.'
                      : 'Lengkapi detail produk baru untuk tokomu.',
                  style: const TextStyle(color: Color(0xFF7A8279), fontSize: 13),
                ),
                const SizedBox(height: 22),
                _FormField(
                  label: 'Nama produk',
                  controller: _nameController,
                  hint: 'Contoh: Kopi susu',
                  validator: (value) => _required(value, 'Nama produk'),
                ),
                const SizedBox(height: 15),
                _FormField(
                  label: 'Kategori',
                  controller: _categoryController,
                  hint: 'Contoh: Minuman',
                  validator: (value) => _required(value, 'Kategori'),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        label: 'Harga (Rp)',
                        controller: _priceController,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) => _nonNegativeInteger(value, 'Harga'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        label: 'Stok',
                        controller: _stockController,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) => _nonNegativeInteger(value, 'Stok'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF245B45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Simpan perubahan' : 'Simpan produk',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF394239),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }
}

IconData _categoryIcon(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('minum')) return Icons.local_cafe_rounded;
  if (normalized.contains('makan')) return Icons.lunch_dining_rounded;
  if (normalized.contains('cemil')) return Icons.cookie_rounded;
  return Icons.inventory_2_outlined;
}

String _formatRupiah(int amount) {
  final digits = amount.toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      formatted.write('.');
    }
    formatted.write(digits[index]);
  }
  return 'Rp ${formatted.toString()}';
}
