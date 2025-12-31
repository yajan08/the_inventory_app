import 'package:cloud_firestore/cloud_firestore.dart';

// Centralized Field Names
class ItemFields {
  static const String name = 'name';
  static const String quantity = 'quantity';
  static const String minQuantity = 'minQuantity';
  static const String isLow = 'isLow';
  static const String note = 'note';
  static const String location = 'location';
  static const String timeCreated = 'timeCreated';
}

class Item {
  String name;
  int quantity;
  int minQuantity;
  String note;
  String location;
  Timestamp timeCreated;

  Item({
    this.name = 'no Name',
    this.quantity = 0,
    this.minQuantity = 0,
    this.note = 'No note',
    this.location = 'Not set',
    Timestamp? timeCreated,
  }) : timeCreated = timeCreated ?? Timestamp.now();

  Map<String, dynamic> toMap() => {
        ItemFields.name: name,
        ItemFields.quantity: quantity,
        ItemFields.minQuantity: minQuantity,
        ItemFields.isLow: quantity <= minQuantity,
        ItemFields.note: note,
        ItemFields.location: location,
        ItemFields.timeCreated: timeCreated,
      };
}

class FirestoreService {
  final CollectionReference items = FirebaseFirestore.instance.collection('items');
  final CollectionReference logs = FirebaseFirestore.instance.collection('logs');
  final CollectionReference bannedUsers = FirebaseFirestore.instance.collection('banned_users'); // Added

  // --- BAN LOGIC ---
  Future<void> banUser(String uid, String email, String reason) async {
    await bannedUsers.doc(uid).set({
      'bannedEmail': email,
      'reason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unbanUser(String uid) async {
    await bannedUsers.doc(uid).delete();
  }

  // --- ITEM LOGIC ---
  Future<void> addItem(Item item) => items.add(item.toMap());

  Stream<QuerySnapshot> getItemsStream() {
    return items
        .orderBy(ItemFields.isLow, descending: true)
        .orderBy(ItemFields.timeCreated, descending: true)
        .snapshots();
  }

  Future<void> updateItem(String docId, Item newItem, String userEmail) async {
    final itemRef = items.doc(docId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(itemRef);
      if (!snapshot.exists) throw Exception('Item does not exist');

      final oldQty = snapshot[ItemFields.quantity] as int;
      if (oldQty != newItem.quantity) {
        transaction.set(logs.doc(), {
          'itemId': docId,
          'userEmail': userEmail,
          'itemName': snapshot[ItemFields.name],
          'quantityBefore': oldQty,
          'quantityAfter': newItem.quantity,
          'timeEdited': Timestamp.now(),
        });
      }
      transaction.update(itemRef, newItem.toMap());
    });
  }

  Future<void> deleteItem(String docId) async {
    final itemRef = items.doc(docId);
    bool hasMoreLogs = true;
    while (hasMoreLogs) {
      final logSnap = await logs.where('itemId', isEqualTo: docId).limit(450).get();
      if (logSnap.docs.isEmpty) break;
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in logSnap.docs) { batch.delete(doc.reference); }
      await batch.commit();
    }
    await itemRef.delete();
  }
}