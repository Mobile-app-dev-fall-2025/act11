import 'package:flutter/material.dart';
import 'models.dart';
import 'repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  const CardOrganizerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});
  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final repo = Repo();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: FutureBuilder(
        future: repo.folderSummaries(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardsScreen(folder: it.folder),
                  ),
                ),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: it.previewUrl == null
                            ? const Icon(Icons.folder, size: 64)
                            : Image.network(
                                it.previewUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported)),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(it.folder.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            CircleAvatar(
                                radius: 14, child: Text('${it.count}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final Folder folder;
  const CardsScreen({super.key, required this.folder});
  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final repo = Repo();
  static const minCards = 3;
  static const maxCards = 6;
  Future<void> _addCardDialog() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final suit = widget.folder.name;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (e.g., Ace)'),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final cards = await repo.cardsInFolder(widget.folder.id!);
                if (cards.length >= maxCards) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('This folder can only hold 6 cards.')),
                    );
                  }
                  return;
                }
                await repo.addCard(CardItem(
                  name: nameCtrl.text.trim().isEmpty
                      ? 'New'
                      : nameCtrl.text.trim(),
                  suit: suit,
                  imageUrl: urlCtrl.text.trim(),
                  folderId: widget.folder.id!,
                ));
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              } catch (e) {
                debugPrint('Error adding card: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(CardItem card) async {
    await repo.deleteCard(card);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.name} Cards'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addCardDialog),
        ],
      ),
      body: FutureBuilder(
        future: repo.cardsInFolder(widget.folder.id!),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snap.data!;
          if (cards.length < minCards) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('You need at least 3 cards in this folder.')),
              );
            });
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final card = cards[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: card.imageUrl.isEmpty
                              ? const Icon(Icons.style, size: 64)
                              : Image.network(
                                  card.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            card.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteCard(card),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
