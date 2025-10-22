import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDb {
  static final AppDb _i = AppDb._();
  AppDb._();
  factory AppDb() => _i;
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'card_organizer.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            suit TEXT NOT NULL,
            image_url TEXT NOT NULL,
            folder_id INTEGER NOT NULL,
            FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE
          );
        ''');
        for (final s in Suit.values) {
          await db.insert('folders', Folder(name: suitToText(s)).toMap());
        }
        Future<void> seedSuit(Suit s, int folderId) async {
          for (int v = 1; v <= 3; v++) {
            final name = switch (v) {
              1 => 'Ace',
              11 => 'Jack',
              12 => 'Queen',
              13 => 'King',
              _ => '$v',
            };
            await db.insert(
              'cards',
              CardItem(
                name: name,
                suit: suitToText(s),
                imageUrl: imageUrl(s, v),
                folderId: folderId,
              ).toMap(),
            );
          }
        }

        final rows = await db.query('folders');
        final idBySuit = {
          for (final r in rows) r['name'] as String: r['id'] as int
        };
        await seedSuit(Suit.hearts, idBySuit['Hearts']!);
        await seedSuit(Suit.spades, idBySuit['Spades']!);
        await seedSuit(Suit.diamonds, idBySuit['Diamonds']!);
        await seedSuit(Suit.clubs, idBySuit['Clubs']!);
      },
    );
    return _db!;
  }

  Future<List<Folder>> getFolders() async {
    final db = await database;
    final rows = await db.query('folders', orderBy: 'id ASC');
    return rows.map(Folder.fromMap).toList();
  }

  Future<int> getFolderCardCount(int folderId) async {
    final db = await database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM cards WHERE folder_id=?', [folderId]);
    return (res.first['c'] as int?) ?? 0;
  }

  Future<String?> getFirstImageUrlForFolder(int folderId) async {
    final db = await database;
    final r = await db.query('cards',
        where: 'folder_id=?',
        whereArgs: [folderId],
        orderBy: 'id ASC',
        limit: 1);
    if (r.isEmpty) return null;
    return r.first['image_url'] as String?;
  }

  static const int minCards = 3;
  static const int maxCards = 6;
  Future<void> createCard(CardItem item) async {
    final db = await database;
    final count = await getFolderCardCount(item.folderId);
    if (count >= maxCards) {
      throw Exception('This folder can only hold $maxCards cards.');
    }
    await db.insert('cards', item.toMap());
  }

  Future<void> updateCard(CardItem item) async {
    final db = await database;
    await db.update('cards', item.toMap(), where: 'id=?', whereArgs: [item.id]);
  }

  Future<void> deleteCard(int id, {required int folderId}) async {
    final db = await database;
    await db.delete('cards', where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.delete('cards', where: 'folder_id=?', whereArgs: [folderId]);
    await db.delete('folders', where: 'id=?', whereArgs: [folderId]);
  }
}

String imageUrl(Suit suit, int value) {
  final suitKey = switch (suit) {
    Suit.hearts => 'hearts',
    Suit.spades => 'spades',
    Suit.diamonds => 'diamonds',
    Suit.clubs => 'clubs',
  };
  final name = switch (value) {
    1 => 'A',
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    _ => '$value',
  };
  return 'https://example.com/cards/$suitKey/$name.png';
}
