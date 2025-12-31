import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class GlobalLogsPage extends StatefulWidget {
  const GlobalLogsPage({super.key});

  @override
  State<GlobalLogsPage> createState() => _GlobalLogsPageState();
}

class _GlobalLogsPageState extends State<GlobalLogsPage> {
  String logQuery = '';
  // Toggle states: 0 = All, 1 = Stock In, 2 = Stock Out
  int selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              hintText: 'Search items, users, dates, or qty...',
              hintStyle: WidgetStateProperty.all(const TextStyle(color: Colors.grey, fontSize: 14)),
              leading: const Icon(Icons.search, color: Color(0xFF124d95), size: 20),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (value) => setState(() => logQuery = value),
            ),
          ),

          // 2. FILTER CHIPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _filterChip(0, "All"),
                const SizedBox(width: 8),
                _filterChip(1, "Stock In"),
                const SizedBox(width: 8),
                _filterChip(2, "Stock Out"),
              ],
            ),
          ),

          // 3. LOG LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('logs')
                  .orderBy('timeEdited', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading logs'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final allLogs = snapshot.data!.docs;

                final filteredLogs = allLogs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // A. Filter by Movement Type (Buttons)
                  final int before = data['quantityBefore'] ?? 0;
                  final int after = data['quantityAfter'] ?? 0;
                  final int diff = after - before;
                  
                  if (selectedFilter == 1 && diff <= 0) return false;
                  if (selectedFilter == 2 && diff >= 0) return false;

                  // B. MASTER SEARCH LOGIC
                  if (logQuery.isEmpty) return true;

                  String normalize(dynamic value) => (value ?? '').toString().toLowerCase().replaceAll(' ', '');
                  final q = normalize(logQuery);

                  // Prepare data for searching
                  final String itemName = normalize(data['itemName']);
                  final String userEmail = normalize(data['userEmail']);
                  final String qtyBefore = normalize(before);
                  final String qtyAfter = normalize(after);
                  final String change = (diff >= 0 ? '+' : '') + diff.toString();
                  
                  // Handle Date Searching (Month name, DD/MM/YYYY)
                  final DateTime dt = (data['timeEdited'] as Timestamp).toDate();
                  final String monthName = DateFormat('MMMM').format(dt).toLowerCase();
                  final String fullDate = DateFormat('dd/MM/yyyy').format(dt);

                  // Combine all fields into one searchable "Super String"
                  final String searchPool = itemName + userEmail + qtyBefore + qtyAfter + change + monthName + fullDate;

                  return searchPool.contains(q);
                }).toList();

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Text('No matching logs found', 
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index].data() as Map<String, dynamic>;
                    return _buildLogTile(log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final bool isSelected = selectedFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => selectedFilter = index),
      selectedColor: const Color(0xFF124d95),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
      ),
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final int before = log['quantityBefore'] ?? 0;
    final int after = log['quantityAfter'] ?? 0;
    final int diff = after - before;
    final bool isStockIn = diff > 0;
    final Color accentColor = isStockIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
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
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['itemName'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log['userEmail'] ?? 'Unknown User',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _badge('$before → $after', Colors.grey.shade100, Colors.blueGrey.shade700),
                          const SizedBox(width: 8),
                          _badge(
                            isStockIn ? '+${diff.abs()}' : '-${diff.abs()}', 
                            accentColor.withAlpha(10), 
                            accentColor
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _formatTimestamp(log['timeEdited']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return [const Text('--')];
    final DateTime dt = (timestamp as Timestamp).toDate();
    final String dateStr = DateFormat('dd/MM/yyyy').format(dt);
    final String timeStr = DateFormat('hh:mm a').format(dt);

    return [
      Text(dateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      const SizedBox(height: 2),
      Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
    ];
  }
}