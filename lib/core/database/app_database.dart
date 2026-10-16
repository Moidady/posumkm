import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Database lokal SQLite untuk aplikasi PosUmkm.
/// Menerapkan ACID transactions, WAL mode, dan identitas UUID v4.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_umkm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Aktifkan foreign key support dan Write-Ahead Logging (WAL) untuk latensi sub-1ms
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Kategori
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Tabel Produk
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        base_price INTEGER NOT NULL,
        sku TEXT NOT NULL,
        image_url TEXT NOT NULL DEFAULT '',
        is_available INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel Modifier / Varian Produk
    await db.execute('''
      CREATE TABLE product_modifiers (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        extra_price INTEGER NOT NULL DEFAULT 0,
        group_name TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabel Pengaturan Toko & Owner WhatsApp
    await db.execute('''
      CREATE TABLE store_settings (
        id TEXT PRIMARY KEY,
        store_name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        owner_whatsapp_number TEXT NOT NULL,
        owner_pin_hash TEXT NOT NULL
      )
    ''');

    // 5. Tabel Shift Kasir & Rekonsiliasi Kas
    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        cashier_name TEXT NOT NULL,
        opened_at INTEGER NOT NULL,
        closed_at INTEGER,
        starting_cash INTEGER NOT NULL,
        actual_cash INTEGER,
        system_cash INTEGER,
        cash_in INTEGER NOT NULL DEFAULT 0,
        cash_out INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'OPEN'
      )
    ''');

    // 6. Tabel Kas Masuk & Kas Keluar Kecil
    await db.execute('''
      CREATE TABLE cash_movements (
        id TEXT PRIMARY KEY,
        shift_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        notes TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts (id) ON DELETE CASCADE
      )
    ''');

    // 7. Tabel Pesanan (Order)
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        shift_id TEXT,
        subtotal INTEGER NOT NULL,
        discount_amount INTEGER NOT NULL DEFAULT 0,
        tax_amount INTEGER NOT NULL DEFAULT 0,
        total_amount INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        cash_tendered INTEGER NOT NULL DEFAULT 0,
        change_due INTEGER NOT NULL DEFAULT 0,
        qris_reference_no TEXT,
        qris_scanned_timestamp TEXT,
        qris_proof_image_path TEXT,
        status TEXT NOT NULL DEFAULT 'PAID',
        created_at INTEGER NOT NULL,
        hlc_timestamp TEXT NOT NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts (id)
      )
    ''');

    // 8. Tabel Detail Item Pesanan (Order Items)
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        selected_modifiers_json TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // 9. Tabel Antrean Mutasi CRDT (Sync Queue)
    await db.execute('''
      CREATE TABLE crdt_mutations (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        hlc_timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Inisialisasi Data Awal Menu UMKM & Pengaturan Toko
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed Pengaturan Toko
    await db.insert('store_settings', {
      'id': 'default-store',
      'store_name': 'Kedai Pos UMKM',
      'address': 'Jl. Kuliner No. 12, Foodcourt Stand B-04',
      'phone_number': '0812-3456-7890',
      'owner_whatsapp_number': '081234567890',
      'owner_pin_hash': '123456', // Default PIN Owner
    });

    // Seed Kategori Menu
    final categories = [
      {'id': 'cat-1', 'name': 'Makanan Ringan', 'icon': 'fastfood', 'sort_order': 1},
      {'id': 'cat-2', 'name': 'Minuman Segar', 'icon': 'local_bar', 'sort_order': 2},
      {'id': 'cat-3', 'name': 'Boba Series', 'icon': 'bubble_chart', 'sort_order': 3},
      {'id': 'cat-4', 'name': 'Kopi & Matcha', 'icon': 'coffee', 'sort_order': 4},
      {'id': 'cat-5', 'name': 'Roti & Keju', 'icon': 'bakery_dining', 'sort_order': 5},
    ];

    for (final cat in categories) {
      await db.insert('categories', {
        ...cat,
        'updated_at': now,
        'is_deleted': 0,
      });
    }

    // Seed Produk Menu F&B
    final products = [
      {
        'id': 'prod-1',
        'category_id': 'cat-1',
        'name': 'Lumpia Celembu Crispy',
        'base_price': 15000,
        'sku': 'LMP-CLM',
        'modifiers': [
          {'name': 'Ekstra Saus Manis Pedas', 'extra_price': 2000, 'group': 'Topping Ekstra'},
          {'name': 'Ekstra Cabe Rawit', 'extra_price': 1000, 'group': 'Topping Ekstra'},
        ]
      },
      {
        'id': 'prod-2',
        'category_id': 'cat-1',
        'name': 'Lumpia Ubi Ungu Lumer',
        'base_price': 15000,
        'sku': 'LMP-UBI',
        'modifiers': [
          {'name': 'Taburan Keju Parut', 'extra_price': 3000, 'group': 'Topping Ekstra'},
          {'name': 'Susu Kental Manis', 'extra_price': 2000, 'group': 'Topping Ekstra'},
        ]
      },
      {
        'id': 'prod-3',
        'category_id': 'cat-2',
        'name': 'Mojito Lime Mint Classic',
        'base_price': 18000,
        'sku': 'MJT-LME',
        'modifiers': [
          {'name': 'Normal Sugar', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'Less Sugar 50%', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'No Sugar', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'Extra Nata De Coco', 'extra_price': 3000, 'group': 'Topping Ekstra'},
        ]
      },
      {
        'id': 'prod-4',
        'category_id': 'cat-2',
        'name': 'Mojito Berry Blast',
        'base_price': 20000,
        'sku': 'MJT-BRY',
        'modifiers': [
          {'name': 'Normal Sugar', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'Less Sugar 50%', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'Extra Basil Seeds', 'extra_price': 2000, 'group': 'Topping Ekstra'},
        ]
      },
      {
        'id': 'prod-5',
        'category_id': 'cat-3',
        'name': 'Brown Sugar Milk Boba',
        'base_price': 22000,
        'sku': 'BBA-BRN',
        'modifiers': [
          {'name': 'Normal Ice', 'extra_price': 0, 'group': 'Level Es'},
          {'name': 'Less Ice', 'extra_price': 0, 'group': 'Level Es'},
          {'name': 'Extra Boba Pearls', 'extra_price': 4000, 'group': 'Topping Ekstra'},
          {'name': 'Cheese Foam Topping', 'extra_price': 5000, 'group': 'Topping Ekstra'},
        ]
      },
      {
        'id': 'prod-6',
        'category_id': 'cat-4',
        'name': 'Pure Uji Matcha Latte',
        'base_price': 24000,
        'sku': 'MTC-LAT',
        'modifiers': [
          {'name': 'Normal Sweetness', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'Less Sweet 50%', 'extra_price': 0, 'group': 'Level Gula'},
          {'name': 'Extra Espresso Shot', 'extra_price': 5000, 'group': 'Topping Ekstra'},
        ]
      },
      {
        'id': 'prod-7',
        'category_id': 'cat-5',
        'name': 'Potato Korean Cheese Bread',
        'base_price': 25000,
        'sku': 'BBD-KRN',
        'modifiers': [
          {'name': 'Double Mozzarella Pull', 'extra_price': 6000, 'group': 'Topping Ekstra'},
          {'name': 'Spicy Honey Glaze', 'extra_price': 3000, 'group': 'Topping Ekstra'},
        ]
      },
    ];

    for (final prod in products) {
      final prodId = prod['id'] as String;
      final modifiers = prod['modifiers'] as List<Map<String, dynamic>>? ?? [];

      await db.insert('products', {
        'id': prodId,
        'category_id': prod['category_id'],
        'name': prod['name'],
        'base_price': prod['base_price'],
        'sku': prod['sku'],
        'image_url': '',
        'is_available': 1,
        'updated_at': now,
        'is_deleted': 0,
      });

      for (final mod in modifiers) {
        await db.insert('product_modifiers', {
          'id': uuid.v4(),
          'product_id': prodId,
          'name': mod['name'],
          'extra_price': mod['extra_price'],
          'group_name': mod['group'],
          'updated_at': now,
        });
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
