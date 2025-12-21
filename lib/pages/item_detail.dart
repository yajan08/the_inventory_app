
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_inventory_app/services/auth_service.dart';
import 'package:the_inventory_app/services/firestore.dart';
import 'package:the_inventory_app/utilities/my_textfield.dart';

class ItemDetail extends StatefulWidget {
  final String docId;

  const ItemDetail({
    super.key,
    required this.docId,
  });

  @override
  State<ItemDetail> createState() => _ItemDetailState();
}

class _ItemDetailState extends State<ItemDetail> {

  Stream<QuerySnapshot> _logsStream() {
  return FirebaseFirestore.instance
      .collection('logs')
      .where('itemId', isEqualTo: widget.docId)
      .orderBy('timeEdited', descending: true)
      .snapshots();
}


  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController minQuantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController stockInOutController = TextEditingController();

  @override
void dispose() {
  nameController.dispose();
  quantityController.dispose();
  minQuantityController.dispose();
  locationController.dispose();
  noteController.dispose();
  stockInOutController.dispose();
  super.dispose();
}

void _confirmDelete() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Item"),
      content: const Text("Are you sure you want to delete this item?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // go back to list
            await FirestoreService().deleteItem(widget.docId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}


// CHANGE 1: add a parameter to control stock in / out
void stockInOutDialog({required bool isStockIn}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      title: Center(
        // CHANGE 2: dynamic title
        child: Text(
          isStockIn ? "Stock In" : "Stock Out",
          style: const TextStyle(
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
                // CHANGE 3: dynamic hint
                hintText: isStockIn
                    ? "Quantity to add..."
                    : "Quantity to remove...",
                obscureText: false,
                controller: stockInOutController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            stockInOutController.clear();
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
            final int currentQty =
                int.tryParse(quantityController.text) ?? 0;
            final int changeQty =
                int.tryParse(stockInOutController.text) ?? 0;

            // CHANGE 4: +/- logic switch
            final int newQty = isStockIn
                ? currentQty + changeQty
                : currentQty - changeQty;

            if (newQty < 0) return; // safety, minimal guard

            quantityController.text = newQty.toString();
            stockInOutController.clear();
            _updateItem();
            Navigator.pop(context);
          },
          child: const Text("Done"),
        ),
      ],
    ),
  );
}

  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Details',
          style: const TextStyle(
            color: Color(0xFFe9f5ff),
          ),
          ),
        backgroundColor: Color(0xFF124d95),
        foregroundColor: Color(0xFFe9f5ff),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete, // call confirmation dialog
          ),
       ],
        ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // final data = snapshot.data!.data() as Map<String, dynamic>;
          final doc = snapshot.data;

if (doc == null || !doc.exists) {
  return const Center(child: Text('Item not found'));
}

final data = doc.data() as Map<String, dynamic>;

          // initialize controllers only once
          if (!_initialized) {
            nameController.text = data['name'] ?? '';
            quantityController.text =
                (data['quantity'] ?? 0).toString();
            minQuantityController.text =
                (data['minQuantity'] ?? 0).toString();
            locationController.text = data['location'] ?? '';
            _initialized = true;
            noteController.text = data['note'] ?? '';
          }

          final quantity = data['quantity'] ?? 0;
          final minQuantity = data['minQuantity'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field("Name", nameController),
                _field("Quantity", quantityController,
                    keyboardType: TextInputType.number),
                _field("Minimum Quantity", minQuantityController,
                    keyboardType: TextInputType.number),
                _field("Location", locationController),
                _field("Notes", noteController),
                const SizedBox(height: 20),
                if (quantity <= minQuantity)
                  const Text(
                    '⚠ Stock is low',
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _updateItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF124d95),
                      foregroundColor: Color(0xFFe9f5ff),
                      minimumSize: const Size.fromHeight(82), // taller button
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20))
                    ),
                    child: const Text("Save Changes"),
                  ),
                ),
                const SizedBox(height: 32),

const Text(
  "Logs",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

StreamBuilder<QuerySnapshot>(
  stream: _logsStream(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Text(
        'No logs yet',
        style: TextStyle(color: Colors.grey),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        final log = snapshot.data!.docs[index].data() as Map<String, dynamic>;

        final before = log['quantityBefore'] as int;
final after = log['quantityAfter'] as int;
final delta = after - before;
final isStockIn = delta > 0;

return Card(
  margin: const EdgeInsets.symmetric(vertical: 6),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT ICON (full visual weight)
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isStockIn ? Colors.green : Colors.orange).withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isStockIn ? Icons.add : Icons.remove,
            color: isStockIn ? Colors.green : Colors.orange,
            size: 28,
          ),
        ),

        const SizedBox(width: 12),

        // RIGHT CONTENT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: delta + before/after
              Row(
                children: [
                  Text(
                    '${delta > 0 ? '+' : ''}$delta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isStockIn ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$before → $after',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // USER EMAIL
              Text(
                log['userEmail'] ?? 'Unknown user',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 2),

              // DATE TIME
              Text(
                _formatTimestamp(log['timeEdited']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
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


              ],
            ),
          );
        },
      ),

      // stock in and out buttons below
    bottomNavigationBar: Container(
  padding: const EdgeInsets.all(16),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            // stock out button pressed
            stockInOutDialog(isStockIn: false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF124d95),
            foregroundColor: Colors.orange,
            minimumSize: const Size.fromHeight(82), // taller button
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20))
          ),
          child: const Text("Stock Out"),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: (){
            // show stock in pop up
            stockInOutDialog(isStockIn: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF124d95),
            foregroundColor: Colors.green,
            minimumSize: const Size.fromHeight(82), // taller button
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20))
          ),
          child: const Text("Stock In"),
        ),
      ),
    ],
  ),
),

    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter $label...',
          hintStyle: TextStyle(
          color: Colors.blue.shade300
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                BorderSide(color: Colors.blue.shade800),
          ),

          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.blue.shade300),
          ),
        ),
      ),
    );
  }

void _updateItem() {
  final item = Item(
    name: nameController.text,
    quantity: int.tryParse(quantityController.text) ?? 0,
    minQuantity: int.tryParse(minQuantityController.text) ?? 0,
    location: locationController.text,
    note: noteController.text,
  );

  // get current email
  final userEmail = AuthService().getCurrentUser()?.email ?? 'unknown';

  // pass email to updateItem
  FirestoreService().updateItem(widget.docId, item, userEmail);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Item updated')),
  );
  Navigator.pop(context); // go back after update
}


//   void _updateItem() {

// // pass currentemail here. to add it to logs later.

//     final item = Item(
//       name: nameController.text,
//       quantity: int.tryParse(quantityController.text) ?? 0,
//       minQuantity: int.tryParse(minQuantityController.text) ?? 0,
//       location: locationController.text,
//       note: noteController.text,
//     );

//     FirestoreService().updateItem(widget.docId, item);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Item updated')),
//     );
//     Navigator.pop(context);
//     // showdialog also does pop, this also does pop, so user goes back to home page directly.
//   }
// }


String _formatTimestamp(Timestamp timestamp) {
  final dt = timestamp.toDate();
  return '${dt.day.toString().padLeft(2, '0')} '
      '${_month(dt.month)} ${dt.year} · '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

String _month(int m) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return months[m - 1];
}
}