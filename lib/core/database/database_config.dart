class DatabaseConfig {
  // Prevents instantiation and extension
  DatabaseConfig._();

  static const String dbPath = 'app_database.db';
  static const int version = 2;

  static const String userTableName = 'User';
  static const String categoryTableName = 'Category';
  static const String productTableName = 'Product';
  static const String transactionTableName = 'Transaction';
  static const String cashierTableName = 'Cashier';
  static const String orderedProductTableName = 'OrderedProduct';
  static const String queuedActionTableName = 'QueuedAction';

  static const String createUserTable =
      '''
CREATE TABLE IF NOT EXISTS '$userTableName' (
    'id' TEXT NOT NULL,
    'email' TEXT,
    'phone' TEXT,
    'name' TEXT,
    'gender' TEXT,
    'birthdate' TEXT,
    'imageUrl' TEXT,
    'authProvider' TEXT,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id')
);
''';

  static const String createCategoryTable = '''
CREATE TABLE IF NOT EXISTS '$categoryTableName' (
      'id' INTEGER PRIMARY KEY AUTOINCREMENT,
      'name' TEXT NOT NULL,
      'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createProductTable = '''
CREATE TABLE IF NOT EXISTS '$productTableName' (
      'id' INTEGER NOT NULL,
      'createdById' TEXT,
      'categoryId' INTEGER,
      'name' TEXT,
      'imageUrl' TEXT,
      'isAvailable' BOOL DEFAULT 1,
      'sold' INTEGER,
      'price' INTEGER,
      'description' TEXT,
      'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
      'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ('id'),
      FOREIGN KEY ('createdById') REFERENCES 'User' ('id'),
      FOREIGN KEY ('categoryId') REFERENCES '$categoryTableName' ('id') ON DELETE SET NULL
    );
''';

  static const String createTransactionTable =
      '''
CREATE TABLE IF NOT EXISTS '$transactionTableName' (
    'id' INTEGER NOT NULL,
    'paymentMethod' TEXT,
    'customerName' TEXT,
    'description' TEXT,
    'createdById' TEXT,
    'receivedAmount' INTEGER,
    'returnAmount' INTEGER,
    'totalAmount' INTEGER,
    'totalOrderedProduct' INTEGER,
    'cashierName' TEXT,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static const String createOrderedProductTable =
      '''
CREATE TABLE IF NOT EXISTS '$orderedProductTableName' (
    'id' INTEGER NOT NULL,
    'transactionId' INTEGER,
    'productId' INTEGER,
    'quantity' INTEGER,
    'name' TEXT,
    'imageUrl' TEXT,
    'price' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('transactionId') REFERENCES 'Transaction' ('id'),
    FOREIGN KEY ('productId') REFERENCES 'Product' ('id')
);
''';

  static const String createQueuedActionTable =
      '''
CREATE TABLE IF NOT EXISTS '$queuedActionTableName' (
    'id' INTEGER NOT NULL,
    'repository' TEXT,
    'method' TEXT,
    'param' TEXT,
    'isCritical' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createCashierTable =
      '''
CREATE TABLE IF NOT EXISTS '$cashierTableName' (
    'id' TEXT NOT NULL,
    'name' TEXT NOT NULL,
    'is_active' INTEGER NOT NULL DEFAULT 1,
    'created_by_id' TEXT NOT NULL,
    'created_at' TEXT,
    'updated_at' TEXT,
    PRIMARY KEY ('id')
);
''';
}
