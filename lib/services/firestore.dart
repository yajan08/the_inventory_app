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
  }) : timeCreated = timeCreated ?? Timestamp.now(), isLow = quantity < minQuantity;

}

class Log {

  String userEmail;
  String quantityBefore;
  String quantityAfter;
  Timestamp timeEdited;

  Log({
    required this.userEmail,
    required this.quantityBefore,
    required this.quantityAfter,
    Timestamp? timeEdited,
  }) : timeEdited = timeEdited ?? Timestamp.now();

}

class FirestoreService {

// get collection of items
final CollectionReference items = FirebaseFirestore.instance.collection('items');

// create item
Future<void> addItem(Item item){
  return items.add({
    'name': item.name,
    'quantity': item.quantity,
    'minQuantity': item.minQuantity,
    'isLow': item.quantity < item.minQuantity,
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
Future<void> updateItem(String docId, Item item){

  // add log object here passing useremail ad item to monitor changes before and after.

    return items.doc(docId).update({
      'name': item.name,
      'quantity': item.quantity,
      'minQuantity': item.minQuantity,
      'isLow': item.quantity < item.minQuantity,
      // not updating time created
      'location': item.location,
      'note': item.note,
    });

  }

// delete item 
Future<void> deleteItem(String docId){
  return items.doc(docId).delete();
}

}