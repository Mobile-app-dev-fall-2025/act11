import 'db.dart';
import 'models.dart';

class Repo {
  final _db = AppDb();
  Future<List<({Folder folder, int count, String? previewUrl})>>
      folderSummaries() async {
    final folders = await _db.getFolders();
    final out = <({Folder folder, int count, String? previewUrl})>[];
    for (final f in folders) {
      final count = await _db.getFolderCardCount(f.id!);
      final preview = await _db.getFirstImageUrlForFolder(f.id!);
      out.add((folder: f, count: count, previewUrl: preview));
    }
    return out;
  }

  Future<List<CardItem>> cardsInFolder(int folderId) async {
    final db = await _db.database;
    final rows = await db.query('cards',
        where: 'folder_id=?', whereArgs: [folderId], orderBy: 'id ASC');
    return rows.map(CardItem.fromMap).toList();
  }

  // pass-throughs that enforce limits
  Future<void> addCard(CardItem item) => _db.createCard(item);
  Future<void> updateCard(CardItem item) => _db.updateCard(item);
  Future<void> deleteCard(CardItem item) =>
      _db.deleteCard(item.id!, folderId: item.folderId);
  Future<void> deleteFolder(int folderId) => _db.deleteFolder(folderId);
}
