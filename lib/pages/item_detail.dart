import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure intl is in pubspec.yaml
import 'package:the_inventory_app/services/auth_service.dart';
import 'package:the_inventory_app/services/firestore.dart';
import 'package:the_inventory_app/utilities/my_textfield.dart';

class ItemDetail extends StatefulWidget {
  final String docId;
  const ItemDetail({super.key, required this.docId});

  @override
  State<ItemDetail> createState() => _ItemDetailState();
}

class _ItemDetailState extends State<ItemDetail> {
  Timestamp? _originalTimeCreated;
  String logSearchQuery = '';
  int selectedLogFilter = 0; // 0: All, 1: In, 2: Out

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

  bool _initialized = false;

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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await FirestoreService().deleteItem(widget.docId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void stockInOutDialog({required bool isStockIn}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(child: Text(isStockIn ? "Stock In" : "Stock Out", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
        content: MyTextField(
          hintText: isStockIn ? "Quantity to add..." : "Quantity to remove...",
          obscureText: false,
          controller: stockInOutController,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              stockInOutController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final int currentQty = int.tryParse(quantityController.text) ?? 0;
              final int changeQty = int.tryParse(stockInOutController.text) ?? 0;
              final int newQty = isStockIn ? currentQty + changeQty : currentQty - changeQty;
              if (newQty < 0) return;
              
              quantityController.text = newQty.toString();
              stockInOutController.clear();
              FocusScope.of(context).unfocus(); // Dismiss keyboard
              Navigator.pop(context);
              Navigator.pop(context);
              await _updateItem(shouldPop: false);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Item Details', style: TextStyle(color: Color(0xFFe9f5ff), fontSize: 18)),
        backgroundColor: const Color(0xFF124d95),
        foregroundColor: const Color(0xFFe9f5ff),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete)],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('items').doc(widget.docId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snapshot.data;
          if (doc == null || !doc.exists) return const Center(child: Text('Item not found'));
          final data = doc.data() as Map<String, dynamic>;

          if (!_initialized) {
            nameController.text = data[ItemFields.name] ?? '';
            quantityController.text = (data[ItemFields.quantity] ?? 0).toString();
            minQuantityController.text = (data[ItemFields.minQuantity] ?? 0).toString();
            locationController.text = data[ItemFields.location] ?? '';
            noteController.text = data[ItemFields.note] ?? '';
            _originalTimeCreated = data[ItemFields.timeCreated] as Timestamp?;
            _initialized = true;
          }

          final int quantity = data[ItemFields.quantity] ?? 0;
          final int minQuantity = data[ItemFields.minQuantity] ?? 0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field("Name", nameController),
                      _field("Quantity", quantityController, keyboardType: TextInputType.number),
                      _field("Minimum Quantity", minQuantityController, keyboardType: TextInputType.number),
                      _field("Location", locationController),
                      _field("Notes", noteController),
                      if (quantity <= minQuantity) 
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('⚠ Stock is low', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ElevatedButton(
                        onPressed: () => _updateItem(shouldPop: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF124d95),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 32),
                      const Text("Activity History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      
                      // LOG SEARCH
                      TextField(
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Search user or month (e.g. Jan)...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) => setState(() => logSearchQuery = val),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _logFilterChip(0, "All"),
                          const SizedBox(width: 8),
                          _logFilterChip(1, "Stock In"),
                          const SizedBox(width: 8),
                          _logFilterChip(2, "Stock Out"),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _logsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  final filteredLogs = snapshot.data!.docs.where((doc) {
                    final logData = doc.data() as Map<String, dynamic>;
                    final int diff = (logData['quantityAfter'] ?? 0) - (logData['quantityBefore'] ?? 0);
                    
                    if (selectedLogFilter == 1 && diff <= 0) return false;
                    if (selectedLogFilter == 2 && diff >= 0) return false;

                    if (logSearchQuery.isEmpty) return true;

                    final DateTime date = (logData['timeEdited'] as Timestamp).toDate();
                    String normalize(dynamic v) => (v ?? '').toString().toLowerCase().replaceAll(' ', '');
                    
                    final q = normalize(logSearchQuery);
                    // Search in User, Month Name, and Full Date string
                    final searchPool = normalize(logData['userEmail']) + 
                                     DateFormat('MMMM').format(date).toLowerCase() + 
                                     DateFormat('dd/MM/yyyy').format(date);
                    
                    return searchPool.contains(q);
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return const SliverToBoxAdapter(child: Center(child: Text('No matching history found', style: TextStyle(color: Colors.grey))));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildElegantLogTile(filteredLogs[index].data() as Map<String, dynamic>),
                        childCount: filteredLogs.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Expanded(child: _actionBtn("Stock Out", const Color(0xFFF59E0B), () => stockInOutDialog(isStockIn: false))),
            const SizedBox(width: 12),
            Expanded(child: _actionBtn("Stock In", const Color(0xFF10B981), () => stockInOutDialog(isStockIn: true))),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantLogTile(Map<String, dynamic> log) {
    final int diff = (log['quantityAfter'] ?? 0) - (log['quantityBefore'] ?? 0);
    final bool isStockIn = diff > 0;
    final Color accentColor = isStockIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final DateTime date = (log['timeEdited'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['userEmail'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${log['quantityBefore']} → ${log['quantityAfter']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Text(isStockIn ? '+${diff.abs()}' : '-${diff.abs()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  Text(DateFormat('hh:mm a').format(date), style: const TextStyle(fontSize: 9, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logFilterChip(int index, String label) {
    final bool isSel = selectedLogFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: const Color(0xFF124d95),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(fontSize: 12, color: isSel ? Colors.white : const Color(0xFF64748B), fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
      onSelected: (val) => setState(() => selectedLogFilter = index),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? Colors.transparent : const Color(0xFFE2E8F0))),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF124d95),
        foregroundColor: color,
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF124d95), width: 1.5)),
        ),
      ),
    );
  }

  Future<void> _updateItem({required bool shouldPop}) async {
    final item = Item(
      name: nameController.text,
      quantity: int.tryParse(quantityController.text) ?? 0,
      minQuantity: int.tryParse(minQuantityController.text) ?? 0,
      location: locationController.text,
      note: noteController.text,
      timeCreated: _originalTimeCreated, 
    );
    final userEmail = AuthService().getCurrentUser()?.email ?? 'unknown';
    try {
      await FirestoreService().updateItem(widget.docId, item, userEmail);
      if (mounted && shouldPop) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}