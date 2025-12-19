import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  void addItemModal(){
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children:[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Add Item"),
              ]
            ),
            Spacer(),
            MyTextField(hintText: "Item Name...", obscureText: false, controller: itemNameController),
            Spacer(),
            MyTextField(hintText: "Quantity...", obscureText: false, controller: itemQuantityController),
            Spacer(),
            MyTextField(hintText: "Minimum Quantity...", obscureText: false, controller: itemMinQuantityController),
            Spacer(),
            MyTextField(hintText: "Note...", obscureText: false, controller: itemNoteController),
            Spacer(),
          ]
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // add new item
              Item item = Item(
               name: itemNameController.text,
               quantity: int.tryParse(itemQuantityController.text) ?? 0,
               minQuantity: int.tryParse(itemMinQuantityController.text) ?? 0,
              note: itemNoteController.text,
             );

              firestoreService.addItem(item);

              // clear text editing controllers
              itemNameController.text = '';
              itemQuantityController.text = '';
              itemMinQuantityController.text = '';
              itemNoteController.text = '';

              // dismiss the alert box
              Navigator.pop(context);
            } , 
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addItemModal,
        child: const Icon(Icons.add),
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

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No items to display'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final document = docs[index];
              final data = document.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'No name';
              final int quantity = data['quantity'] ?? 0;
              final int minQuantity = data['minQuantity'] ?? 0;

              return ListTile(
                title: Text(name),
                subtitle: Text('Qty: $quantity | Min: $minQuantity'),
                trailing: quantity <= minQuantity
                    ? const Icon(Icons.warning, color: Colors.red)
                    : null,
              );
            },
          );
        },
      ),

    );
  }
}
