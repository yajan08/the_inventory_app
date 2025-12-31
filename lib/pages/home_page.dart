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
  final itemNameController = TextEditingController();
  final itemQuantityController = TextEditingController();
  final itemMinQuantityController = TextEditingController();
  final itemNoteController = TextEditingController();
  final itemLocationController = TextEditingController();
  
  String query = '';

  @override
  void dispose() {
    itemNameController.dispose(); 
    itemQuantityController.dispose();
    itemMinQuantityController.dispose(); 
    itemNoteController.dispose();
    itemLocationController.dispose();
    super.dispose();
  }

  void addItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add New Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(hintText: "Name", obscureText: false, controller: itemNameController),
              const SizedBox(height: 12),
              MyTextField(hintText: "Quantity", obscureText: false, controller: itemQuantityController, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              MyTextField(hintText: "Min Quantity", obscureText: false, controller: itemMinQuantityController, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              MyTextField(hintText: "Location", obscureText: false, controller: itemLocationController),
              const SizedBox(height: 12),
              MyTextField(hintText: "Note", obscureText: false, controller: itemNoteController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF124d95), foregroundColor: Colors.white),
            onPressed: () {
              firestoreService.addItem(Item(
                name: itemNameController.text,
                quantity: int.tryParse(itemQuantityController.text) ?? 0,
                minQuantity: int.tryParse(itemMinQuantityController.text) ?? 0,
                location: itemLocationController.text,
                note: itemNoteController.text,
              ));
              _clearControllers();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    itemNameController.clear(); itemQuantityController.clear();
    itemMinQuantityController.clear(); itemLocationController.clear();
    itemNoteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton( // Restored standard size
        onPressed: addItemDialog,
        backgroundColor: const Color(0xFF124d95),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              hintText: 'Search items...',
              hintStyle: WidgetStateProperty.all(const TextStyle(color: Colors.grey, fontSize: 14)),
              leading: const Icon(Icons.search, color: Color(0xFF124d95), size: 22),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final itemsList = snapshot.data!.docs;
                final filteredDocs = itemsList.where((doc) {
                  if (query.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  String normalize(dynamic value) => (value ?? '').toString().toLowerCase().replaceAll(' ', '');
                  final q = normalize(query);
                  return normalize(data[ItemFields.name]).contains(q) || 
                         normalize(data[ItemFields.location]).contains(q) || 
                         normalize(data[ItemFields.note]).contains(q) ||
                         normalize(data[ItemFields.quantity]).contains(q);
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return _buildElegantItemTile(doc.id, doc.data() as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantItemTile(String docId, Map<String, dynamic> data) {
    final int qty = data[ItemFields.quantity] ?? 0;
    final int min = data[ItemFields.minQuantity] ?? 0;
    final bool isLow = qty <= min;
    final Color accentColor = isLow ? const Color(0xFFEF4444) : const Color(0xFF124d95);

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Spacious spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: accentColor), // Substantial indicator
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data[ItemFields.name] ?? 'No name',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                      ),
                      if (isLow) 
                        const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 20),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _standardBadge('Qty: $qty', accentColor.withAlpha(25), accentColor),
                        if ((data[ItemFields.location] ?? '').isNotEmpty)
                          _standardBadge(data[ItemFields.location], const Color(0xFFF1F5F9), const Color(0xFF64748B)),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => ItemDetail(docId: docId))
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _standardBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}