import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBanPage extends StatefulWidget {
  const UserBanPage({super.key});

  @override
  State<UserBanPage> createState() => _UserBanPageState();
}

class _UserBanPageState extends State<UserBanPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF124d95);

  Future<void> _banUser() async {
    final email = _emailController.text.trim();
    final reason = _reasonController.text.trim();

    if (email.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and reason")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Find the User UID from the email in your 'Users' collection
      final userSnap = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        throw "User not found in database.";
      }

      final String targetUid = userSnap.docs.first.id;

      // 2. Add to banned_users collection
      await FirebaseFirestore.instance.collection('banned_users').doc(targetUid).set({
        'bannedEmail': email,
        'reason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
      });

      _emailController.clear();
      _reasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Banned $email")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unbanUser(String uid) async {
    await FirebaseFirestore.instance.collection('banned_users').doc(uid).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User unbanned")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ban New User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "User Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Reason",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _banUser,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Ban User"),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Currently Banned", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('banned_users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text("No banned users.");

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(top: 10),
                      child: ListTile(
                        title: Text(data['bannedEmail'] ?? 'Unknown'),
                        subtitle: Text("Reason: ${data['reason']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.green),
                          onPressed: () => _unbanUser(docs[index].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}