import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_inventory_app/pages/item_detail.dart';
import 'package:the_inventory_app/services/firestore.dart';
import 'package:the_inventory_app/utilities/my_textfield.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final FirestoreService firestoreService = FirestoreService();

// text controllers 
 TextEditingController itemNameController = TextEditingController();
 TextEditingController itemQuantityController = TextEditingController();
 TextEditingController itemMinQuantityController = TextEditingController();
 TextEditingController itemNoteController = TextEditingController();
 TextEditingController itemLocationController = TextEditingController();
 
 String query = '';

 @override
  void dispose() {
    // Dispose all controllers to free memory
    itemNameController.dispose();
    itemQuantityController.dispose();
    itemMinQuantityController.dispose();
    itemNoteController.dispose();
    itemLocationController.dispose();

    super.dispose(); // always call super.dispose() last
  }

void addItemDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      title: const Center(
        child: Text(
          "Add Item",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              MyTextField(
                hintText: "Name",
                obscureText: false,
                controller: itemNameController,
              ),
              const SizedBox(height: 12),
              MyTextField(
                hintText: "Quantity",
                obscureText: false,
                controller: itemQuantityController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              MyTextField(
                hintText: "Min Quantity",
                obscureText: false,
                controller: itemMinQuantityController,
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 12),
              MyTextField(
                hintText: "Location",
                obscureText: false,
                controller: itemLocationController,
              ),
              const SizedBox(height: 12),
              MyTextField(
                hintText: "Note",
                obscureText: false,
                controller: itemNoteController,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Item item = Item(
              name: itemNameController.text,
              quantity: int.tryParse(itemQuantityController.text) ?? 0,
              minQuantity: int.tryParse(itemMinQuantityController.text) ?? 0,
              location: itemLocationController.text,
              note: itemNoteController.text,
            );

            firestoreService.addItem(item);

            itemNameController.text = '';
            itemQuantityController.text = '';
            itemMinQuantityController.text = '';
            itemLocationController.text = '';
            itemNoteController.text = '';

            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Inventory", style: TextStyle(color: Color(0xFFe9f5ff))),
      //   backgroundColor: Color(0xFF124d95),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: addItemDialog,
        backgroundColor: Color(0xFF124d95),
        child: const Icon(Icons.add, color: Color(0xFFe9f5ff)),
      ),

      body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(12.0),
      child: SearchBar(
      hintText: 'Search items...',
      leading: const Icon(Icons.search),
      elevation: WidgetStateProperty.all(0), // Removes the shadow
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Adjust for desired roundness
        ),
      ),
        onChanged: (value) {
          setState(() {
            query = value.toLowerCase();
          });
        },
      )
    ),
    Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List itemsList = snapshot.data!.docs;

          // Apply search filter
          if (query.isNotEmpty) {
          // 1. Remove all spaces from the query once
          final normalizedQuery = query.toLowerCase().replaceAll(' ', '');

          itemsList = itemsList.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Helper function to clean strings for comparison
            String normalize(dynamic value) {
              return (value ?? '').toString().toLowerCase().replaceAll(' ', '');
            }

            final name = normalize(data['name']);
            final note = normalize(data['note']);
            final location = normalize(data['location']);
            final quantity = (data['quantity'] ?? 0).toString(); // Quantity usually has no spaces

            return name.contains(normalizedQuery) ||
                  note.contains(normalizedQuery) ||
                  location.contains(normalizedQuery) ||
                  quantity.contains(normalizedQuery);
          }).toList();
        }

          if (itemsList.isEmpty) {
            return Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory,
                  size: 80,
                  color: Color(0x80124d95),
                  ),
              Text(
                'No items to display',
                style: TextStyle(
                  fontSize: 34,
                  color: Color(0x80124d95),
                ),
                ),
              ]
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: itemsList.length,
            itemBuilder: (context, index) {
              final document = itemsList[index];
              final data = document.data() as Map<String, dynamic>;
              final docId = document.id;
              final name = data['name'] ?? 'No name';
              final quantity = data['quantity'] ?? 0;
              final minQuantity = data['minQuantity'] ?? 0;

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Only show the red status bar if quantity is low
                      if (quantity <= minQuantity)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 5, // Thin accent bar
                          child: Container(color: Colors.red),
                        ),
                      
                      ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF124d95),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined, 
                                size: 14, 
                                color: Colors.grey.shade600
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Qty: $quantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: quantity <= minQuantity
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_rounded, 
                                  color: Colors.red, 
                                  size: 18
                                ),
                              )
                            : Icon(
                                Icons.arrow_forward_ios_rounded, 
                                color: Colors.grey.shade300, 
                                size: 14
                              ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ItemDetail(docId: docId)),
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
    ),
  ],
),

      backgroundColor: Color(0xFFe9f5ff),
    );
  }
}
