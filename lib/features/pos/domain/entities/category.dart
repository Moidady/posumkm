import 'package:equatable/equatable.dart';

/// Entitas kategori produk menu UMKM (contoh: Makanan Ringan, Minuman Segar, Boba, dll).
class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  @override
  List<Object?> get props => [id, name, icon, sortOrder];
}
