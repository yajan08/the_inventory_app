import 'package:cloud_firestore/cloud_firestore.dart';

class Item {

  String name;
  int quantity;
  int minQuantity;
  bool isLow;
  String note;
  Timestamp timeCreated;
  String location;

Item({
    this.name = 'no Name',
    this.quantity = 0,
    this.minQuantity = 0,
    this.note = 'No note',
    Timestamp? timeCreated,
    this.location = 'Not set'
  }) : timeCreated = timeCreated ?? Timestamp.now(), isLow = quantity <= minQuantity;

}
class Log {

  String userEmail;
  int quantityBefore;
  int quantityAfter;
  Timestamp timeEdited;

  Log({
    required this.userEmail,
    required this.quantityBefore,
    required this.quantityAfter,
    Timestamp? timeEdited,
  }) : timeEdited = timeEdited ?? Timestamp.now();

}

// the log model can have a better implementation... with log class having required fields directly and using them later.

class FirestoreService {

// get collection of items
final CollectionReference items = FirebaseFirestore.instance.collection('items');

final CollectionReference logs = FirebaseFirestore.instance.collection('logs');

// create item
Future<void> addItem(Item item){
  return items.add({
    'name': item.name,
    'quantity': item.quantity,
    'minQuantity': item.minQuantity,
    'isLow': item.quantity <= item.minQuantity,
    'timeCreated': Timestamp.now(),
    'location': item.location,
    'note': item.note,
  });
}

// read items 
Stream<QuerySnapshot> getItemsStream(){

  final itemsStream = items
  .orderBy('isLow', descending: true) // true first
  .orderBy('timeCreated', descending: true)
  .snapshots();

  return itemsStream;
}

// update items 
Future<void> updateItem(String docId, Item newItem, String userEmail) async {
  final itemRef = items.doc(docId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(itemRef);

    if (!snapshot.exists) {
      throw Exception('Item does not exist');
    }

    final oldQuantity = snapshot['quantity'] as int;
    final newQuantity = newItem.quantity;

    if (newQuantity < 0) {
      throw Exception('Quantity cannot be negative');
    }

    final itemName = snapshot['name'] as String;

    // create log only if quantity changed
    if (oldQuantity != newQuantity) {
      final bool isStockIn = newQuantity > oldQuantity;
      final int diff = newQuantity - oldQuantity;

      final log = {
        'itemId': docId,

        // original data
        'userEmail': userEmail,
        'itemName': itemName,
        'quantityBefore': oldQuantity,
        'quantityAfter': newQuantity,

        // 🔥 PRECOMPUTED SEARCH FIELDS
        'userEmailLower': userEmail.toLowerCase(),
        'itemNameLower': itemName.toLowerCase(),
        'movement': isStockIn ? 'stock in' : 'stock out',
        'diff': diff,

        'timeEdited': Timestamp.now(),
      };

      transaction.set(logs.doc(), log);
    }

    // if (oldQuantity != newQuantity) {
      
    //   final log = {
    //     'itemId': docId,
    //     'userEmail': userEmail, // <- use passed email
    //     'itemName': itemName,
    //     'quantityBefore': oldQuantity,
    //     'quantityAfter': newQuantity,
    //     'timeEdited': Timestamp.now(),
    //   };

    //   final logRef = logs.doc();
    //   transaction.set(logRef, log);
    // }

    // update item
    transaction.update(itemRef, {
      'name': newItem.name,
      'quantity': newQuantity,
      'minQuantity': newItem.minQuantity,
      'isLow': newQuantity <= newItem.minQuantity,
      'location': newItem.location,
      'note': newItem.note,
    });
  });
}

// delete item without log
// Future<void> deleteItem(String docId){
//   return items.doc(docId).delete();
// }

// delete item 
// below code to also delete the log if item is deleted.
Future<void> deleteItem(String docId) async {
  final WriteBatch batch = FirebaseFirestore.instance.batch();

  // 1. Reference the item document
  final DocumentReference itemRef = items.doc(docId);
  batch.delete(itemRef);

  // 2. Find all logs associated with this itemId
  final QuerySnapshot logSnapshots = await logs.where('itemId', isEqualTo: docId).get();

  // 3. Add each log deletion to the batch
  for (var doc in logSnapshots.docs) {
    batch.delete(doc.reference);
  }

  // 4. Commit the batch
  return batch.commit();
}

// ADD: helper to write a log
Future<void> addLog({
  required String itemId,
  required Log log,
}) {
  return logs.add({
    'itemId': itemId,
    'userEmail': log.userEmail,
    'quantityBefore': log.quantityBefore,
    'quantityAfter': log.quantityAfter,
    'timeEdited': log.timeEdited,
  });
}

}