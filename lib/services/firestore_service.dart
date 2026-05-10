import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) {
    return _db.collection('users').doc(uid).collection('tasks');
  }

  Stream<List<TaskModel>> getTasksStream(String uid) {
    return _tasks(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .where((task) => task.userId == uid)
              .toList(),
        );
  }

  Future<void> addTask(TaskModel task) async {
    try {
      final ref = task.id.isEmpty
          ? _tasks(task.userId).doc()
          : _tasks(task.userId).doc(task.id);
      await ref.set(task.copyWith(id: ref.id).toMap());
    } catch (_) {
      throw Exception('Something went wrong, try again');
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _tasks(task.userId).doc(task.id).update(task.toMap());
    } catch (_) {
      throw Exception('Something went wrong, try again');
    }
  }

  Future<void> deleteTask(String uid, String taskId) async {
    try {
      await _tasks(uid).doc(taskId).delete();
    } catch (_) {
      throw Exception('Something went wrong, try again');
    }
  }

  Future<void> toggleTaskStatus(
    String uid,
    String taskId,
    String newStatus,
  ) async {
    try {
      await _tasks(uid).doc(taskId).update({'status': newStatus});
    } catch (_) {
      throw Exception('Something went wrong, try again');
    }
  }
}
