import 'package:cloud_firestore/cloud_firestore.dart';

class Item {

  String name;
  int quantity;
  int minQuantity;
  bool isLow;
  String note;
  Timestamp timeCreated;

Item({
    this.name = 'no Name',
    this.quantity = 0,
    this.minQuantity = 0,
    this.note = 'no Note',
    Timestamp? timeCreated,
  }) : timeCreated = timeCreated ?? Timestamp.now(), isLow = quantity < minQuantity;

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

}