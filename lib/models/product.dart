class Product {
  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
  });

  final int? id;
  final String name;
  final String category;
  final int price;
  final int stock;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id']! as int,
      name: map['name']! as String,
      category: map['category']! as String,
      price: map['price']! as int,
      stock: map['stock']! as int,
    );
  }
}
