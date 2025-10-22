enum Suit { hearts, spades, diamonds, clubs }

String suitToText(Suit s) => switch (s) {
      Suit.hearts => 'Hearts',
      Suit.spades => 'Spades',
      Suit.diamonds => 'Diamonds',
      Suit.clubs => 'Clubs',
    };
Suit suitFromText(String s) => Suit.values.firstWhere(
      (v) => suitToText(v) == s,
      orElse: () => Suit.hearts,
    );

class Folder {
  final int? id;
  final String name; // Hearts, Spades, Diamonds, Clubs
  final DateTime createdAt;
  Folder({this.id, required this.name, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
  static Folder fromMap(Map<String, Object?> m) => Folder(
        id: m['id'] as int?,
        name: m['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

class CardItem {
  final int? id;
  final String name; // e.g., "Ace of Hearts" or "7"
  final String suit; // Hearts/Spades/Diamonds/Clubs
  final String imageUrl;
  final int folderId; // FK -> folders.id
  CardItem({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    required this.folderId,
  });
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'suit': suit,
        'image_url': imageUrl,
        'folder_id': folderId,
      };
  static CardItem fromMap(Map<String, Object?> m) => CardItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        suit: m['suit'] as String,
        imageUrl: m['image_url'] as String,
        folderId: m['folder_id'] as int,
      );
}
