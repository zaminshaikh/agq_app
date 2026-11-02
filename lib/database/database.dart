import 'package:agq_app/content/app_content.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/database/models/activity_model.dart';
import 'package:agq_app/database/models/graph_point_model.dart';
import 'package:agq_app/database/models/notification_model.dart';
import 'package:agq_app/database/models/assets_model.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:agq_app/screens/utils/utilities.dart';

/// A service class for interacting with the Firestore database.
///
/// This class handles operations related to the user's data in Firestore,
/// such as fetching client data, updating fields, and managing notifications.
class DatabaseService {
  String? cid; // Client ID: Document ID in Firestore
  String? uid; // User ID: Firebase Auth UID

  // Flag to indicate if the user is connected to another user
  // This is so we don't fetch the connected user's connected users and avoid infinite recursion
  bool isConnectedUser = false;

  static final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'));

  CollectionReference? assetsSubCollection;
  CollectionReference? activitiesSubCollection;
  CollectionReference? notificationsSubCollection;
  CollectionReference? graphPointsSubCollection;
  List<dynamic>? connectedUsersCIDs;

  /// Constructs a [DatabaseService] instance with the given [uid].
  DatabaseService(this.uid);

  /// Constructs a [DatabaseService] instance for a connected user with the given [cid].
  DatabaseService.connectedUser(this.cid) {
    setSubCollections(this);
    isConnectedUser = true;
  }

  /// Constructs a [DatabaseService] instance with the given [uid] and [cid].
  DatabaseService.withCID(this.uid, this.cid);

  /// Asynchronously creates a [DatabaseService] instance by fetching the [cid] for the given [uid].
  ///
  /// Returns a [Future] that completes with a [DatabaseService] instance or `null` if the [uid] is not found.
  /// Each user in Firestore has a document with a unique [uid] field. If the [uid] is found, the method fetches the [cid] and connected users from the document.

  static Future<DatabaseService?> fetchCID(
      String uid, BuildContext context) async {
    DatabaseService db = DatabaseService(uid);

    // Access Firestore and get the document
    QuerySnapshot querySnapshot =
        await usersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.size > 0) {
      log('database.dart: UID $uid found in Firestore.');

      // Document found, access the 'cid' field
      QueryDocumentSnapshot snapshot = querySnapshot.docs.first;
      db.cid = snapshot.id;

      // Cast snapshot.data() to Map<String, dynamic>
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Check if 'connectedUsers' field exists before trying to access it
      if (data.containsKey('connectedUsers')) {
        db.connectedUsersCIDs = data['connectedUsers'] ?? [];
      } else {
        log('database.dart: Field "connectedUsers" does not exist in document.');
        db.connectedUsersCIDs = []; // Or handle this case as needed
      }

      setSubCollections(db);
    } else {
      log('database.dart: Document with UID $uid not found in Firestore.');
      // log('database.dart: User signed out.');
      // await FirebaseAuth.instance.signOut();
      return null;
    }

    return db;
  }

  /// Sets the sub-collections for the given [DatabaseService] instance.
  ///
  /// This includes assets, activities, notifications, and graph points sub-collections.
  static void setSubCollections(DatabaseService db) {
    db.assetsSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('ASSETS_SUBCOLLECTION'));
    db.graphPointsSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('GRAPHPOINTS_SUBCOLLECTION'));
    db.activitiesSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('ACTIVITIES_SUBCOLLECTION'));
    db.notificationsSubCollection = usersCollection
        .doc(db.cid)
        .collection(Config.get('NOTIFICATIONS_SUBCOLLECTION'));
  }

  /// Returns a stream that listens to changes in the user's client data and sub-collections.
  ///
  /// The stream emits [Client] objects containing updated client data whenever changes occur.
  Stream<Client?> getClientStream() {
    if (cid == null) {
      return Stream.value(null);
    }

    log('database.dart: Fetching client stream for CID: $cid');

    try {
      // Stream for the main client document
      Stream<DocumentSnapshot> clientDocumentStream =
          usersCollection.doc(cid).snapshots();

      // Stream for connected users
      Stream<List<Client?>> connectedUsersStream;
      if (!isConnectedUser &&
          connectedUsersCIDs != null &&
          connectedUsersCIDs!.isNotEmpty) {
        connectedUsersStream =
            Rx.combineLatestList(connectedUsersCIDs!.map((connectedCid) {
          DatabaseService db = DatabaseService.connectedUser(connectedCid);
          return db.getClientStream().asBroadcastStream();
        }).toList())
                .asBroadcastStream();
      } else {
        connectedUsersStream = Stream.value([null]);
      }

      // Stream for the activities sub-collection
      Stream<List<Activity>> activitiesStream = activitiesSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(
                  (doc) => Activity.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      // Stream for the assets sub-collection
      Stream<Assets> assetsStream =
          assetsSubCollection!.snapshots().map((snapshot) {
        Map<String, Fund> funds = {};
        Map<String, dynamic> general = {};

        for (var doc in snapshot.docs) {
          if (doc.id == 'general') {
            general = doc.data() as Map<String, dynamic>;
          } else {
            funds[doc.id] = Fund.fromMap(doc.data() as Map<String, dynamic>);
          }
        }

        return Assets.fromMap(funds, general);
      });

      // Stream for the notifications sub-collection
      Stream<List<Notif?>> notificationsStream = notificationsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                try {
                  return Notif.fromMap(<String, dynamic>{
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                    'parentCID': cid
                  });
                } catch (e) {
                  log('database.dart: Error creating Notif from map: $e');
                  return null;
                }
              }).toList());

      // Stream for the graphPoints sub-collection
      Stream<List<GraphPoint?>> graphPointsStream = graphPointsSubCollection!
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                try {
                  return GraphPoint.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  log('database.dart: Error creating GraphPoint from map: $e');
                  return null;
                }
              }).toList());

      // Combine all the streams into a single stream emitting Client objects
      return Rx.combineLatest6(
          clientDocumentStream,
          activitiesStream,
          assetsStream,
          notificationsStream,
          graphPointsStream,
          connectedUsersStream, (
        DocumentSnapshot clientDoc,
        List<Activity> activities,
        Assets assets,
        List<Notif?> notifications,
        List<GraphPoint?> graphPoints,
        List<Client?> connectedUsers,
      ) {
        final clientData = clientDoc.data() as Map<String, dynamic>?;

        if (clientData == null) {
          log('clientDoc.data() is null for cid: ${cid ?? 'unknown'}');
          return Client.empty();
        }

        // Filter out null values and sort the graphPoints
        List<GraphPoint> filteredGraphPoints =
            graphPoints.whereType<GraphPoint>().toList();
        filteredGraphPoints.sort((a, b) => a.time.compareTo(b.time));

        return Client.fromMap(
          cid: cid,
          clientData,
          activities: activities,
          assets: assets,
          notifications: notifications
              .whereType<Notif>()
              .toList(), // Filter out null values
          graphPoints: filteredGraphPoints,
          connectedUsers: connectedUsers.whereType<Client>().toList(),
        );
      });
    } catch (e) {
      log('database.dart: Error in getClientStream: $e');
      return Stream.value(null);
    }
  }

  /// Returns a field from the user document.
  ///
  /// Parameters:
  /// - [fieldName]: The name of the field to retrieve.
  ///
  /// Returns:
  /// - A [Future] that completes with the value of the specified field, or `null` if the field does not exist.
  Future<dynamic> getField(String fieldName) async {
    try {
      DocumentSnapshot userDoc = await usersCollection.doc(cid).get();
      if (userDoc.exists) {
        if ((userDoc.data() as Map<String, dynamic>).containsKey(fieldName)) {
          return userDoc.get(fieldName);
        } else {
          return null; // Field does not exist
        }
      } else {
        throw Exception(AppContent.text(
            'text.database.database.user_document_does_not_exist_9150d8'));
      }
    } catch (e) {
      log('database.dart: Error getting field: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Updates a field in the user document.
  ///
  /// Parameters:
  /// - [fieldName]: The name of the field to update.
  /// - [newValue]: The new value to set for the field.
  ///
  /// Returns:
  /// - A [Future] that completes when the field is updated.
  Future<void> updateField(String fieldName, dynamic newValue) async {
    try {
      await usersCollection.doc(cid).update({fieldName: newValue});
    } catch (e) {
      throw Exception(AppContent.text(
          'text.database.database.error_updating_field_e_2075b0', {'e': e}));
    }
  }

  /// Marks a specific notification as read.
  ///
  /// Parameters:
  /// - [notificationId]: The ID of the notification to mark as read.
  ///
  /// Returns:
  /// - A [Future] that completes with `true` if successful, `false` otherwise.
  Future<bool> markNotificationAsRead(String notificationId) async {
    if (cid == null) {
      log('CID is null');
      return false;
    } else if (notificationsSubCollection == null) {
      setSubCollections(this);
    }
    if (notificationsSubCollection == null) {
      log('notificationsSubCollection is null, try checking the path.');
      return false;
    }
    try {
      DocumentReference docRef =
          notificationsSubCollection!.doc(notificationId);

      DocumentSnapshot docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update({'isRead': true});
        return true;
      }
    } catch (e) {
      log('Error updating notification: $e');
    }
    return false;
  }

  /// Marks all notifications as read for the current user and connected users.
  ///
  /// Returns:
  /// - A [Future] that completes with `true` if successful, `false` otherwise.
  Future<bool> markAllNotificationsAsRead() async {
    if (cid == null) {
      log('CID is null');
      return false;
    } else if (notificationsSubCollection == null) {
      setSubCollections(this);
    }
    if (notificationsSubCollection == null) {
      log('notificationsSubCollection is null, try checking the path.');
      return false;
    }
    try {
      DocumentSnapshot clientSnapshot = await usersCollection.doc(cid).get();
      QuerySnapshot querySnapshot = await notificationsSubCollection!.get();

      List<Future> futures = [];

      if (querySnapshot.size > 0) {
        for (DocumentSnapshot doc in querySnapshot.docs) {
          futures.add(doc.reference.update({'isRead': true}));
        }
      }

      Map<String, dynamic>? clientData =
          clientSnapshot.data() as Map<String, dynamic>?;
      if (clientData != null && clientData['connectedUsers'] != null) {
        for (String connectedCid in clientData['connectedUsers']) {
          futures.add(DatabaseService.withCID('', connectedCid)
              .markAllNotificationsAsRead());
        }
      }

      await Future.wait(futures);
      return true;
    } catch (e) {
      log('Error updating notifications: $e');
    }
    return false;
  }

  /// Links a new user to the database using the provided email.
  ///
  /// This method fetches the existing data for the user with the given [cid] (Client ID) from the database.
  /// Each [cid] corresponds to a document in the 'users' collection in the database.
  /// If the user already exists (determined by the presence of a [uid] in the existing data), an exception is thrown.
  /// Otherwise, the method updates the existing data with the new user's [uid] and [email] and sets the document in the database with the updated data.
  ///
  /// Throws a [FirebaseException] if:
  /// - **No document found**
  ///   - The document does not exist for the given [cid]
  /// - **User already exists**
  ///   - The document we pulled has a non-empty [uid], meaning a user already exists for the given [cid]
  ///
  /// Catches any other unhandled exceptions and logs an error message.
  ///
  /// Parameters:
  /// - [email]: The email of the new user to be linked to the database.
  ///
  /// Usage:
  /// ```dart
  /// try {
  ///   DatabaseService db = new DatabaseService(cid, uid);
  ///   await db.linkUserToDatabase(email, cid);
  ///   log('database.dart: User linked to database successfully.');
  /// } catch (e) {
  ///   log('database.dart: Error linking user to database: $e');
  /// }
  /// ```
  ///
  /// Returns a [Future] that completes when the document is successfully set in the database.
  Future<void> linkNewUser(String email) async {
    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('linkNewUser');
      final result = await callable.call({
        'email': email,
        'cid': cid,
        'uid': uid,
        'usersCollectionID': Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION')
      });
      log('Function result: ${result.data}');
    } catch (e) {
      log('Error calling cloud function: $e');
    }
  }

  /// Returns a stream of [DocumentSnapshot] containing a single user document.
  ///
  /// This stream will emit a new [DocumentSnapshot] whenever the user document is updated.
  Stream<DocumentSnapshot> get getUser => usersCollection.doc(cid).snapshots();

  /// Checks if a document exists in the Firestore 'users' collection.
  ///
  /// This function invokes a callable Cloud Function named 'checkDocumentExists' and passes it
  /// a document ID ('cid') to check for existence in the Firestore database. This is useful
  /// for client-side checks against database conditions without exposing direct database access.
  ///
  /// [cid] The ID of the document to check for existence.
  ///
  /// Returns a [Future] that completes with a boolean value indicating whether the document exists.
  /// If the Cloud Function call fails, it logs the error and returns false, assuming non-existence
  /// to safely handle potential failures.
  ///
  /// Usage:
  /// ```dart
  /// bool exists = await checkDocumentExists('some-document-id');
  /// ```
  Future<bool> checkDocumentExists(String cid) async {
    try {
      // Create an instance of the callable function 'checkDocumentExists' from Firebase Functions
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('checkDocumentExists');

      // Call the function with 'cid' as the parameter
      final result = await callable.call({
        'cid': cid,
        'usersCollectionID': Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION')
      });

      // Return the boolean result from the function call
      return result.data['exists'] as bool;
    } catch (e) {
      // Log any errors encountered during the function call
      log('Error calling function: $e');

      // Return false by default if an error occurs to handle the error gracefully
      return false;
    }
  }

  /// Checks if a document with a specific ID is linked to a user.
  ///
  /// This function makes a call to a Firebase Cloud Function named 'checkDocumentLinked'
  /// to determine if the document in the Firestore 'users' collection has a non-empty
  /// 'uid' field, indicating it is linked to a user.
  ///
  /// The function is wrapped in a try-catch block to handle any potential errors
  /// that might occur during the execution of the cloud function, such as network issues
  /// or problems with the cloud function itself.
  ///
  /// [cid] The ID of the document to check.
  ///
  /// Returns a [Future] that completes with a boolean value indicating whether the document
  /// is linked to a user. If the cloud function call fails, it logs the error and returns false.
  ///
  /// Example usage:
  /// ```dart
  /// bool isLinked = await checkDocumentLinked('documentId123');
  /// ```
  Future<bool> checkDocumentLinked(String cid) async {
    try {
      // Create an instance of the callable function 'checkDocumentLinked' from Firebase Functions
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('checkDocumentLinked');

      // Call the function with 'cid' as the parameter
      final result = await callable.call({
        'cid': cid,
        'usersCollectionID': Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION')
      });

      // Return the boolean result from the function call
      return result.data['isLinked'] as bool;
    } catch (e) {
      // Log any errors encountered during the function call
      log('Error calling function: $e');

      // Return true by default if an error occurs to handle the error gracefully
      return true;
    }
  }

  Future<bool> isUIDLinked(String uid) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      log('No network detected. Returning false immediately.');
      return false; // or handle it differently
    }

    try {
      // Initialize the callable function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'isUIDLinked',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      // Call the function with the required parameters
      final HttpsCallableResult result = await callable.call({
        'uid': uid,
        'usersCollectionID': Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION'),
      });

      // Extract the 'isLinked' value from the result
      final data = result.data as Map<String, dynamic>;
      final bool isLinked = data['isLinked'] as bool;

      return isLinked;
    } on FirebaseFunctionsException catch (e) {
      // Handle Firebase Functions errors
      log('Firebase Functions Exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      // Handle other errors
      log('Unknown error occurred while calling isUIDLinked: $e');
      return false;
    }
  }
}
