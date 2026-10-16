import 'package:flutter/foundation.dart';
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
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    if (!kIsWeb) {
      try {
        await db.execute('PRAGMA journal_mode = WAL');
      } catch (_) {
        // WAL mode fallback
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _replaceWithOfficialCatalog(db);
    }
    if (oldVersion < 3) {
      await _ensureMultiDeviceSchema(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'",
      );
      if (tables.isEmpty) {
        await _createDB(db, 3);
      } else {
        // Cek apakah masih menggunakan kategori lama ('cat-1') atau belum ada 'cat-lumpia'
        final lumpiaCat = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: ['cat-lumpia'],
        );
        if (lumpiaCat.isEmpty) {
          await _replaceWithOfficialCatalog(db);
        }
        await _ensureMultiDeviceSchema(db);
      }
    } catch (e) {
      debugPrint('Database auto-repair notice: $e');
    }
  }

  Future<void> _ensureMultiDeviceSchema(Database db) async {
    // 1. Pastikan tabel users untuk login multi-HP kasir tersedia
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        pin_code TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'CASHIER',
        assigned_device TEXT NOT NULL DEFAULT 'HP-KASIR-1',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    // 2. Pastikan kolom cashier_name dan device_name ada pada tabel orders
    final orderCols = await db.rawQuery('PRAGMA table_info(orders)');
    final colNames = orderCols.map((c) => c['name'] as String).toSet();
    if (!colNames.contains('cashier_name')) {
      await db.execute(
        "ALTER TABLE orders ADD COLUMN cashier_name TEXT NOT NULL DEFAULT 'Kasir 1'",
      );
    }
    if (!colNames.contains('device_name')) {
      await db.execute(
        "ALTER TABLE orders ADD COLUMN device_name TEXT NOT NULL DEFAULT 'HP-KASIR-1'",
      );
    }

    // 3. Seed akun default jika tabel users masih kosong
    await _seedDefaultUsers(db);
  }

  Future<void> _seedDefaultUsers(Database db) async {
    final existing = await db.query('users', limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final defaultUsers = [
      {
        'id': 'user-owner',
        'username': 'owner',
        'full_name': 'Owner / Admin Utama',
        'pin_code': '123456',
        'role': 'OWNER',
        'assigned_device': 'HP-OWNER',
        'is_active': 1,
        'created_at': now,
      },
      {
        'id': 'user-kasir-1',
        'username': 'kasir1',
        'full_name': 'Kasir 1 (HP Utama)',
        'pin_code': '111111',
        'role': 'CASHIER',
        'assigned_device': 'HP-KASIR-1',
        'is_active': 1,
        'created_at': now,
      },
      {
        'id': 'user-kasir-2',
        'username': 'kasir2',
        'full_name': 'Kasir 2 (HP Kedua)',
        'pin_code': '222222',
        'role': 'CASHIER',
        'assigned_device': 'HP-KASIR-2',
        'is_active': 1,
        'created_at': now,
      },
      {
        'id': 'user-kasir-3',
        'username': 'kasir3',
        'full_name': 'Kasir 3 (Tablet / Booth)',
        'pin_code': '333333',
        'role': 'CASHIER',
        'assigned_device': 'TABLET-KASIR-3',
        'is_active': 1,
        'created_at': now,
      },
    ];

    for (final u in defaultUsers) {
      await db.insert(
        'users',
        u,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _replaceWithOfficialCatalog(Database db) async {
    await db.delete('product_modifiers');
    await db.delete('products');
    await db.delete('categories');
    await _seedCatalogData(db);
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
        cashier_name TEXT NOT NULL DEFAULT 'Kasir 1',
        device_name TEXT NOT NULL DEFAULT 'HP-KASIR-1',
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

    // 10. Tabel Akun Kasir & Perangkat Multi-HP
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        pin_code TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'CASHIER',
        assigned_device TEXT NOT NULL DEFAULT 'HP-KASIR-1',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    // Inisialisasi Data Awal Menu UMKM, Akun Kasir, & Pengaturan Toko
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed Pengaturan Toko
    await db.insert(
      'store_settings',
      {
        'id': 'default-store',
        'store_name': 'Kedai Pos UMKM',
        'address': 'Jl. Kuliner No. 12, Foodcourt Stand B-04',
        'phone_number': '0812-3456-7890',
        'owner_whatsapp_number': '081234567890',
        'owner_pin_hash': '123456',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await _seedDefaultUsers(db);
    await _seedCatalogData(db);
  }

  Future<void> _seedCatalogData(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    // =========================================================================
    // 5 KATEGORI RESMI SESUAI INSTRUKSI & DAFTAR MENU GAMBAR OUTLET
    // =========================================================================
    final categories = [
      {'id': 'cat-lumpia', 'name': 'LUMPIA', 'icon': 'fastfood', 'sort_order': 1},
      {
        'id': 'cat-potato',
        'name': 'POTATO KOREAN CHEESE BREAD',
        'icon': 'bakery_dining',
        'sort_order': 2
      },
      {'id': 'cat-boba', 'name': 'BOBA SERIES', 'icon': 'bubble_chart', 'sort_order': 3},
      {'id': 'cat-matcha', 'name': 'MATCHA SERIES', 'icon': 'emoji_food_beverage', 'sort_order': 4},
      {'id': 'cat-mojito', 'name': 'MOJITO SERIES', 'icon': 'local_bar', 'sort_order': 5},
    ];

    for (final cat in categories) {
      await db.insert(
        'categories',
        {
          ...cat,
          'updated_at': now,
          'is_deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Pilihan Ubi untuk Lumpia (1. Ubi Ungu, 2. Ubi Cilembu)
    final lumpiaUbiModifiers = [
      {'name': '1. Ubi Ungu', 'extra_price': 0, 'group': 'Pilihan Ubi'},
      {'name': '2. Ubi Cilembu', 'extra_price': 0, 'group': 'Pilihan Ubi'},
      {'name': 'Mix Ubi Ungu & Cilembu', 'extra_price': 0, 'group': 'Pilihan Ubi'},
    ];

    // Pilihan Isian & Toping Tabur untuk Potato Korean Cheese Bread
    final potatoModifiers = [
      {'name': '1. Ubi Ungu', 'extra_price': 0, 'group': 'Pilihan Isian'},
      {'name': '2. Ubi Cilembu', 'extra_price': 0, 'group': 'Pilihan Isian'},
      {'name': '3. Kentang', 'extra_price': 0, 'group': 'Pilihan Isian'},
      {'name': 'Toping Tabur: Keju Parut', 'extra_price': 0, 'group': 'Toping Tabur'},
      {'name': 'Toping Tabur: Oreo', 'extra_price': 0, 'group': 'Toping Tabur'},
      {'name': 'Toping Tabur: Taro', 'extra_price': 0, 'group': 'Toping Tabur'},
      {'name': 'Toping Tabur: Matcha', 'extra_price': 0, 'group': 'Toping Tabur'},
    ];

    // Pilihan Gula/Es Standar Minuman
    final drinkModifiers = [
      {'name': 'Normal Ice & Sugar', 'extra_price': 0, 'group': 'Takaran Es & Gula'},
      {'name': 'Less Sugar', 'extra_price': 0, 'group': 'Takaran Es & Gula'},
      {'name': 'Less Ice', 'extra_price': 0, 'group': 'Takaran Es & Gula'},
    ];

    final List<Map<String, dynamic>> products = [
      // =======================================================================
      // 1. KATEGORI: LUMPIA (Ubi Ungu & Ubi Cilembu)
      // =======================================================================
      {
        'id': 'lmp-01',
        'category_id': 'cat-lumpia',
        'name': 'Lumpia Original (Ubi Ungu)',
        'base_price': 15000,
        'sku': 'LMP-ORG-UNG',
        'image_url': 'assets/images/products/lumpia_original_ungu.jpg',
        'modifiers': lumpiaUbiModifiers,
      },
      {
        'id': 'lmp-02',
        'category_id': 'cat-lumpia',
        'name': 'Lumpia Original (Ubi Cilembu)',
        'base_price': 15000,
        'sku': 'LMP-ORG-CLM',
        'image_url': 'assets/images/products/lumpia_original_cilembu.jpg',
        'modifiers': lumpiaUbiModifiers,
      },
      {
        'id': 'lmp-03',
        'category_id': 'cat-lumpia',
        'name': 'Lumpia Toping Coklat',
        'base_price': 18000,
        'sku': 'LMP-CKL',
        'image_url': 'assets/images/products/lumpia_coklat.jpg',
        'modifiers': lumpiaUbiModifiers,
      },
      {
        'id': 'lmp-04',
        'category_id': 'cat-lumpia',
        'name': 'Lumpia Tiramisu Mix Coklat',
        'base_price': 18000,
        'sku': 'LMP-TRM',
        'image_url': 'assets/images/products/lumpia_tiramisu_coklat.jpg',
        'modifiers': lumpiaUbiModifiers,
      },
      {
        'id': 'lmp-05',
        'category_id': 'cat-lumpia',
        'name': 'Lumpia Toping Matcha',
        'base_price': 18000,
        'sku': 'LMP-MTC',
        'image_url': 'assets/images/products/lumpia_matcha.jpg',
        'modifiers': lumpiaUbiModifiers,
      },
      {
        'id': 'lmp-06',
        'category_id': 'cat-lumpia',
        'name': 'Lumpia Toping Mozarella',
        'base_price': 20000,
        'sku': 'LMP-MOZ',
        'image_url': 'assets/images/products/lumpia_mozarella.jpg',
        'modifiers': lumpiaUbiModifiers,
      },

      // =======================================================================
      // 2. KATEGORI: POTATO KOREAN CHEESE BREAD (Ubi Ungu, Ubi Cilembu, Kentang)
      // =======================================================================
      {
        'id': 'pkc-01',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Original',
        'base_price': 22000,
        'sku': 'PKC-ORG',
        'image_url': 'assets/images/products/potato_original.jpg',
        'modifiers': potatoModifiers,
      },
      {
        'id': 'pkc-02',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Double Mozzarella',
        'base_price': 28000,
        'sku': 'PKC-DBL',
        'image_url': 'assets/images/products/potato_double_mozzarella.jpg',
        'modifiers': potatoModifiers,
      },
      {
        'id': 'pkc-03',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Coklat',
        'base_price': 25000,
        'sku': 'PKC-CKL',
        'image_url': 'assets/images/products/potato_coklat.jpg',
        'modifiers': potatoModifiers,
      },
      {
        'id': 'pkc-04',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Tiramisu',
        'base_price': 25000,
        'sku': 'PKC-TRM',
        'image_url': 'assets/images/products/potato_tiramisu.jpg',
        'modifiers': potatoModifiers,
      },
      {
        'id': 'pkc-05',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Taro',
        'base_price': 25000,
        'sku': 'PKC-TRO',
        'image_url': 'assets/images/products/potato_taro.jpg',
        'modifiers': potatoModifiers,
      },
      {
        'id': 'pkc-06',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Matcha',
        'base_price': 25000,
        'sku': 'PKC-MTC',
        'image_url': 'assets/images/products/potato_matcha.jpg',
        'modifiers': potatoModifiers,
      },
      {
        'id': 'pkc-07',
        'category_id': 'cat-potato',
        'name': 'Cheese Bread Abon Saus Mayo',
        'base_price': 25000,
        'sku': 'PKC-ABN',
        'image_url': 'assets/images/products/potato_abon_mayo.jpg',
        'modifiers': potatoModifiers,
      },

      // =======================================================================
      // 3. KATEGORI: BOBA SERIES (MILK BOBA SERIES 15 K)
      // =======================================================================
      {
        'id': 'bba-01',
        'category_id': 'cat-boba',
        'name': 'Cookies Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-CKS',
        'image_url': 'assets/images/products/boba_cookies.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-02',
        'category_id': 'cat-boba',
        'name': 'Caramel Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-CRM',
        'image_url': 'assets/images/products/boba_cream.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-03',
        'category_id': 'cat-boba',
        'name': 'Honey Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-HNY',
        'image_url': 'assets/images/products/boba_milk.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-04',
        'category_id': 'cat-boba',
        'name': 'Brown Sugar Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-BRN',
        'image_url': 'assets/images/products/boba_cookies.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-05',
        'category_id': 'cat-boba',
        'name': 'Blueberry Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-BLB',
        'image_url': 'assets/images/products/boba_milk.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-06',
        'category_id': 'cat-boba',
        'name': 'Coklat Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-CKL',
        'image_url': 'assets/images/products/boba_cookies.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-07',
        'category_id': 'cat-boba',
        'name': 'Strawberry Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-STR',
        'image_url': 'assets/images/products/boba_cream.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-08',
        'category_id': 'cat-boba',
        'name': 'Ube Cream Boba',
        'base_price': 15000,
        'sku': 'BBA-UBE',
        'image_url': 'assets/images/products/boba_cream.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-09',
        'category_id': 'cat-boba',
        'name': 'Redvelvet Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-RDV',
        'image_url': 'assets/images/products/boba_cream.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'bba-10',
        'category_id': 'cat-boba',
        'name': 'Vanilla Milk Boba',
        'base_price': 15000,
        'sku': 'BBA-VNL',
        'image_url': 'assets/images/products/boba_milk.jpg',
        'modifiers': drinkModifiers,
      },

      // =======================================================================
      // 4. KATEGORI: MATCHA SERIES (PURE MATCHA DAFTAR MENU)
      // =======================================================================
      {
        'id': 'mtc-01',
        'category_id': 'cat-matcha',
        'name': 'Original Matcha',
        'base_price': 13000,
        'sku': 'MTC-ORG',
        'image_url': 'assets/images/products/matcha_original.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-02',
        'category_id': 'cat-matcha',
        'name': 'Honey Matcha',
        'base_price': 15000,
        'sku': 'MTC-HNY',
        'image_url': 'assets/images/products/matcha_honey.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-03',
        'category_id': 'cat-matcha',
        'name': 'Cookies Matcha',
        'base_price': 16000,
        'sku': 'MTC-CKS',
        'image_url': 'assets/images/products/matcha_cookies.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-04',
        'category_id': 'cat-matcha',
        'name': 'Cloud Matcha',
        'base_price': 16000,
        'sku': 'MTC-CLD',
        'image_url': 'assets/images/products/matcha_cloud.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-05',
        'category_id': 'cat-matcha',
        'name': 'Coconut Matcha',
        'base_price': 17000,
        'sku': 'MTC-CCN',
        'image_url': 'assets/images/products/matcha_coconut.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-06',
        'category_id': 'cat-matcha',
        'name': 'Strawberry Matcha',
        'base_price': 18000,
        'sku': 'MTC-STR',
        'image_url': 'assets/images/products/matcha_strawberry.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-07',
        'category_id': 'cat-matcha',
        'name': 'Ube Cream Matcha',
        'base_price': 18000,
        'sku': 'MTC-UBE',
        'image_url': 'assets/images/products/matcha_ube_cream.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-08',
        'category_id': 'cat-matcha',
        'name': 'Redvelvet Matcha',
        'base_price': 18000,
        'sku': 'MTC-RDV',
        'image_url': 'assets/images/products/matcha_redvelvet.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-09',
        'category_id': 'cat-matcha',
        'name': 'Caramel Matcha',
        'base_price': 18000,
        'sku': 'MTC-CRM',
        'image_url': 'assets/images/products/matcha_caramel.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-10',
        'category_id': 'cat-matcha',
        'name': 'Blueberry Matcha',
        'base_price': 18000,
        'sku': 'MTC-BLB',
        'image_url': 'assets/images/products/matcha_blueberry.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-11',
        'category_id': 'cat-matcha',
        'name': 'Coklat Matcha',
        'base_price': 18000,
        'sku': 'MTC-CKL',
        'image_url': 'assets/images/products/matcha_coklat.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mtc-12',
        'category_id': 'cat-matcha',
        'name': 'Vanilla Matcha',
        'base_price': 18000,
        'sku': 'MTC-VNL',
        'image_url': 'assets/images/products/matcha_vanilla.jpg',
        'modifiers': drinkModifiers,
      },

      // =======================================================================
      // 5. KATEGORI: MOJITO SERIES (MOJITO SERIES 10 K)
      // =======================================================================
      {
        'id': 'mjt-01',
        'category_id': 'cat-mojito',
        'name': 'Bubble Gum Mojito',
        'base_price': 10000,
        'sku': 'MJT-BBG',
        'image_url': 'assets/images/products/mojito_blue.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-02',
        'category_id': 'cat-mojito',
        'name': 'Banana Mojito',
        'base_price': 10000,
        'sku': 'MJT-BNN',
        'image_url': 'assets/images/products/mojito_fresh.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-03',
        'category_id': 'cat-mojito',
        'name': 'Strawberry Mojito',
        'base_price': 10000,
        'sku': 'MJT-STR',
        'image_url': 'assets/images/products/mojito_green.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-04',
        'category_id': 'cat-mojito',
        'name': 'Arbei Mojito',
        'base_price': 10000,
        'sku': 'MJT-ARB',
        'image_url': 'assets/images/products/mojito_green.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-05',
        'category_id': 'cat-mojito',
        'name': 'Caramel Mojito',
        'base_price': 10000,
        'sku': 'MJT-CRM',
        'image_url': 'assets/images/products/mojito_fresh.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-06',
        'category_id': 'cat-mojito',
        'name': 'Ocean Blue Mojito',
        'base_price': 10000,
        'sku': 'MJT-OCB',
        'image_url': 'assets/images/products/mojito_blue.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-07',
        'category_id': 'cat-mojito',
        'name': 'Orange Mojito',
        'base_price': 10000,
        'sku': 'MJT-ORG',
        'image_url': 'assets/images/products/mojito_fresh.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-08',
        'category_id': 'cat-mojito',
        'name': 'Lemon Mojito',
        'base_price': 10000,
        'sku': 'MJT-LMN',
        'image_url': 'assets/images/products/mojito_fresh.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-09',
        'category_id': 'cat-mojito',
        'name': 'Granda Apel Mojito',
        'base_price': 10000,
        'sku': 'MJT-APL',
        'image_url': 'assets/images/products/mojito_green.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-10',
        'category_id': 'cat-mojito',
        'name': 'Mangga Mojito',
        'base_price': 10000,
        'sku': 'MJT-MNG',
        'image_url': 'assets/images/products/mojito_fresh.jpg',
        'modifiers': drinkModifiers,
      },
      {
        'id': 'mjt-11',
        'category_id': 'cat-mojito',
        'name': 'Leci Mojito',
        'base_price': 10000,
        'sku': 'MJT-LCI',
        'image_url': 'assets/images/products/mojito_green.jpg',
        'modifiers': drinkModifiers,
      },
    ];

    for (final prod in products) {
      final prodId = prod['id'] as String;
      final modifiers = prod['modifiers'] as List<Map<String, dynamic>>? ?? [];

      await db.insert(
        'products',
        {
          'id': prodId,
          'category_id': prod['category_id'],
          'name': prod['name'],
          'base_price': prod['base_price'],
          'sku': prod['sku'],
          'image_url': prod['image_url'] ?? '',
          'is_available': 1,
          'updated_at': now,
          'is_deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

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
}
