import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:carpinteria_movil_sw2/domain/entities/entity.dart';
import 'package:carpinteria_movil_sw2/core/utils/sql_security_validator.dart';

class SqliteDatabase {
  static Database? _db;

  /// Esquema compacto que se envía al LLM (~110 tokens) para Text-to-SQL.
  /// Jamás expone datos sensibles, solo la estructura de tablas.
  static const String schemaForLlm = '''
Tablas SQLite disponibles:
1. pedidos(id TEXT, cliente_nombre TEXT, producto_nombre TEXT, tipo_madera TEXT, especificaciones TEXT, monto_total REAL, adelanto REAL, saldo REAL, estado TEXT, fecha_entrega TEXT, created_at TEXT)
   - Valores posibles de estado: 'Pendiente', 'En fabricación', 'Listo', 'Entregado'
2. productos(id TEXT, nombre TEXT, categoria TEXT, tipo_madera TEXT, dimensiones TEXT, precio REAL, dias_estimados INTEGER, stock INTEGER)
   - Valores posibles de categoria: 'Mesas', 'Sillas', 'Roperos', 'Puertas', 'Cocina'
3. materiales(id TEXT, nombre TEXT, tipo TEXT, cantidad REAL, unidad TEXT, stock_minimo REAL, costo_unitario REAL, alerta_stock INTEGER)
   - alerta_stock = 1 cuando cantidad <= stock_minimo, 0 cuando el stock es normal.
''';

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'carpinteria_offline_v1.db');

    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE productos (
            id TEXT PRIMARY KEY,
            nombre TEXT,
            categoria TEXT,
            tipo_madera TEXT,
            dimensiones TEXT,
            precio REAL,
            dias_estimados INTEGER,
            stock INTEGER,
            descripcion TEXT,
            icono TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE pedidos (
            id TEXT PRIMARY KEY,
            cliente_nombre TEXT,
            producto_nombre TEXT,
            tipo_madera TEXT,
            especificaciones TEXT,
            monto_total REAL,
            adelanto REAL,
            saldo REAL,
            estado TEXT,
            fecha_entrega TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE materiales (
            id TEXT PRIMARY KEY,
            nombre TEXT,
            tipo TEXT,
            cantidad REAL,
            unidad TEXT,
            stock_minimo REAL,
            costo_unitario REAL,
            alerta_stock INTEGER
          )
        ''');
      },
    );
    return _db!;
  }

  /// Sincroniza en SQLite los productos, pedidos y materiales actuales
  /// (ya sea que provengan del Backend o del modo local) para que estén
  /// disponibles offline para consultas SQL de la IA.
  static Future<void> syncAll({
    required List<ProductEntity> products,
    required List<OrderEntity> orders,
    required List<WoodMaterialEntity> materials,
  }) async {
    final db = await database;
    final batch = db.batch();

    for (final prod in products) {
      batch.insert(
        'productos',
        {
          'id': prod.id,
          'nombre': prod.name,
          'categoria': prod.category,
          'tipo_madera': prod.woodType,
          'dimensiones': prod.dimensions,
          'precio': prod.price,
          'dias_estimados': prod.estimatedDays,
          'stock': prod.stock,
          'descripcion': prod.description,
          'icono': prod.iconName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final ord in orders) {
      batch.insert(
        'pedidos',
        {
          'id': ord.id,
          'cliente_nombre': ord.clientName,
          'producto_nombre': ord.productName,
          'tipo_madera': ord.woodType,
          'especificaciones': ord.specifications,
          'monto_total': ord.totalAmount,
          'adelanto': ord.advancePayment,
          'saldo': ord.totalAmount - ord.advancePayment,
          'estado': ord.status,
          'fecha_entrega': ord.deliveryDate,
          'created_at': ord.createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final mat in materials) {
      batch.insert(
        'materiales',
        {
          'id': mat.id,
          'nombre': mat.name,
          'tipo': mat.type,
          'cantidad': mat.quantity,
          'unidad': mat.unit,
          'stock_minimo': mat.minStock,
          'costo_unitario': mat.costPerUnit,
          'alerta_stock': mat.isLowStock ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Ejecuta únicamente consultas SELECT validadas por [SqlSecurityValidator].
  static Future<List<Map<String, dynamic>>> executeSafeQuery(String rawSql) async {
    final safeSql = SqlSecurityValidator.extractAndValidateSql(rawSql);
    final db = await database;
    return await db.rawQuery(safeSql);
  }
}
