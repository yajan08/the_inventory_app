import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GlobalLogsPage extends StatefulWidget {
  const GlobalLogsPage({super.key});

  @override
  State<GlobalLogsPage> createState() => _GlobalLogsPageState();
}

class _GlobalLogsPageState extends State<GlobalLogsPage> {
  String logQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFe9f5ff),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SearchBar(
              hintText: 'Search logs...',
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
              Color(0x30124d95),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  logQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('logs')
                  .orderBy('timeEdited', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading logs'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      
                final logs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // --- Data Normalization for Search ---
                  final email = (data['userEmail'] ?? '').toString().toLowerCase();
                  final itemName = (data['itemName'] ?? '').toString().toLowerCase();
                  final before = (data['quantityBefore'] ?? 0).toString();
                  final after = (data['quantityAfter'] ?? 0).toString();
                  
                  // Logic for "stock in" or "stock out" text search
                  final int diff = (data['quantityAfter'] ?? 0) - (data['quantityBefore'] ?? 0);
                  final String movement = diff > 0 ? "stock in" : "stock out";
      
                  // For search by data like 08/12 or 21/08/2025 or 12/2025
                  final timestamp = data['timeEdited'];
                  String dateSearch = '';

                  if (timestamp != null && timestamp is Timestamp) {
                    final dt = timestamp.toDate();

                    final day = dt.day.toString().padLeft(2, '0');
                    final month = dt.month.toString().padLeft(2, '0');
                    final year = dt.year.toString();

                    // searchable formats
                    dateSearch = '$day/$month $day/$month/$year';
                  }

                  // Return true if query matches ANY field
                  return email.contains(logQuery) || 
                         itemName.contains(logQuery) || 
                         before.contains(logQuery) || 
                         after.contains(logQuery) ||
                         movement.contains(logQuery)||
                         dateSearch.contains(logQuery);
                }).toList();
      
                if (logs.isEmpty) {
                  return Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment,
                    size: 80,
                    color: Color(0x80124d95),
                    ),
                Text(
                  'No Logs to display',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    return _buildLogCard(log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final int before = log['quantityBefore'] ?? 0;
    final int after = log['quantityAfter'] ?? 0;
    final int diff = after - before;
    final bool isStockIn = diff > 0;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isStockIn ? Colors.green : Colors.orange).withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isStockIn ? Icons.add_circle : Icons.remove_circle,
            color: isStockIn ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          log['itemName'] ?? 'Unknown Item',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF124d95)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log['userEmail'] ?? 'Unknown User'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('$before', style: const TextStyle(fontWeight: FontWeight.w500)),
                const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                Text('$after', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text(
                  isStockIn ? '(+$diff)' : '($diff)',
                  style: TextStyle(
                    color: isStockIn ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end, // RIGHT ALIGN
          children: [
            Text(
              _formatDate(log['timeEdited']),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(log['timeEdited']),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

String _formatDate(dynamic timestamp) {
  if (timestamp == null) return '';
  final dt = (timestamp as Timestamp).toDate();
  return '${dt.day.toString().padLeft(2, '0')}/'
         '${dt.month.toString().padLeft(2, '0')}/'
         '${dt.year}';
}

String _formatTime(dynamic timestamp) {
  if (timestamp == null) return '';
  final dt = (timestamp as Timestamp).toDate();
  return '${dt.hour.toString().padLeft(2, '0')}:'
         '${dt.minute.toString().padLeft(2, '0')}';
}

}

//  String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return '';
//     final DateTime dt = (timestamp as Timestamp).toDate();
//     return "${dt.day}/${dt.month}/${dt.year}\n ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
//   }
// }