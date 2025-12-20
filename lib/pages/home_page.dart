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
              minQuantity:
                  int.tryParse(itemMinQuantityController.text) ?? 0,
              note: itemNoteController.text,
            );

            firestoreService.addItem(item);

            itemNameController.text = '';
            itemQuantityController.text = '';
            itemMinQuantityController.text = '';
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
      appBar: AppBar(
        title: const Text("Inventory", style: TextStyle(color: Color(0xFFe9f5ff))),
        backgroundColor: Color(0xFF124d95),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addItemDialog,
        backgroundColor: Color(0xFF124d95),
        child: const Icon(Icons.add, color: Color(0xFFe9f5ff)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getItemsStream(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List itemsList = snapshot.data!.docs;

          if (itemsList.isEmpty) {
            return Center(
              child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                Icon(Icons.inventory),
                Text('No items to display'),
                ]
              ),
            );
          }

return ListView.builder(
  itemCount: itemsList.length,
  padding: const EdgeInsets.all(12),
  itemBuilder: (context, index) {

    DocumentSnapshot document = itemsList[index];
  
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String docId = document.id;

    final String name = data['name'] ?? 'No name';
    final int quantity = data['quantity'] ?? 0;
    final int minQuantity = data['minQuantity'] ?? 0;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: quantity <= minQuantity
                ? Colors.red
                : const Color(0xFF124d95),
          ),
          
        ),
        elevation: 0,
        child: ListTile(
          title: Text(name),
          subtitle: Text('Qty: $quantity'),
          trailing: quantity <= minQuantity
              ? const Icon(Icons.warning, color: Colors.red)
              : null,
          textColor: const Color(0xFF124d95),
          onTap: () {
          Navigator.push(
          context,
          MaterialPageRoute(
             builder: (_) => ItemDetail(docId: docId),
        ),
      );
    },
        ),
      );
    },
  );
        },
      ),
      backgroundColor: Color(0xFFe9f5ff),
    );
  }
}
