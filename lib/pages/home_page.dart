import 'package:flutter/material.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  final List<String> items = [
    'Apples',
    'Bananas',
    'Milk',
    'Bread',
    'Rice',
    'Sugar',
  ];

  String query = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = items
        .where(
          (item) => item.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // add item logic
        },
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchBar(
              hintText: 'Search inventory...',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredItems[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
