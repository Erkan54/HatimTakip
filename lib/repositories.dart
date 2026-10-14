import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quran.dart';

const verseCount = 6236;
const chunkSize = 10;
const chunkCount = 624;

class ReadingSession {
  const ReadingSession(this.round, this.chunk, this.next);
  final int round, chunk, next;
  int get end => min(verseCount, (chunk + 1) * chunkSize);
}

class HatimRepository {
  HatimRepository(this.db, this.auth, this.quran);
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final Quran quran;
  String get uid => auth.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get me => db.doc('users/$uid');
  DocumentReference<Map<String, dynamic>> get state => db.doc('public/state');
  DocumentReference<Map<String, dynamic>> chunk(int round, int index) =>
      db.doc('publicRounds/$round/chunks/$index');
  DocumentReference<Map<String, dynamic>> group(String id) =>
      db.doc('groups/$id');

  Future<String?> loadName() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final snap = await me.get();
    return snap.data()?['name'] as String?;
  }

  Future<void> register(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 40) {
      throw ArgumentError('Adınızı giriniz (en fazla 40 karakter).');
    }
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    await db.doc('users/${user.uid}').set({
      'name': cleaned,
      'createdAt': FieldValue.serverTimestamp(),
      'groups': <String>[],
    });
  }

  /// Updates only the profile name; historical group/reading records stay intact.
  Future<void> updateName(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 40) {
      throw ArgumentError('Adınızı giriniz (en fazla 40 karakter).');
    }
    await me.update({'name': cleaned});
  }

  String _randomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(16, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  Future<String> createGroup(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 70) {
      throw ArgumentError('Grup adını giriniz (en fazla 70 karakter).');
    }
    final id = db.collection('groups').doc().id;
    final code = _randomCode();
    final batch = db.batch();
    batch.set(group(id), {
      'name': cleaned,
      'owner': uid,
      'inviteCode': code,
      'round': 1,
      'completedHatims': 0,
      'createdAt': FieldValue.serverTimestamp()
    });
    batch.set(db.doc('invites/$code'), {'groupId': id, 'owner': uid});
    batch.set(db.doc('groups/$id/members/$uid'), {
      'uid': uid,
      'name': (await me.get()).data()?['name'],
      'inviteCode': code,
      'joinedAt': FieldValue.serverTimestamp()
    });
    batch.update(me, {
      'groups': FieldValue.arrayUnion([id])
    });
    await batch.commit();
    return id;
  }

  Future<String> joinGroup(String enteredCode) async {
    final code = enteredCode.trim().toUpperCase().replaceAll('-', '');
    final invite = await db.doc('invites/$code').get();
    if (!invite.exists) throw StateError('Bu davet koduyla grup bulunamadı.');
    final id = invite.data()!['groupId'] as String;
    final member = db.doc('groups/$id/members/$uid');
    await db.runTransaction((tx) async {
      final existing = await tx.get(member);
      if (!existing.exists) {
        tx.set(member, {
          'uid': uid,
          'name': (await me.get()).data()?['name'],
          'inviteCode': code,
          'joinedAt': FieldValue.serverTimestamp()
        });
        tx.update(me, {
          'groups': FieldValue.arrayUnion([id])
        });
      }
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> myGroups() async {
    final ids = List<String>.from((await me.get()).data()?['groups'] ?? []);
    final result = <Map<String, dynamic>>[];
    for (final id in ids) {
      final snap = await group(id).get();
      if (snap.exists) result.add({'id': id, ...snap.data()!});
    }
    return result;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> groupStream(String id) =>
      group(id).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> progressStream(
          String id, int round) =>
      db.doc('groups/$id/rounds/$round/progress/main').snapshots();

  Future<void> mark(String id, int round, String key, bool done) async {
    final ref = db.doc('groups/$id/rounds/$round/progress/main');
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final marks = Map<String, dynamic>.from(snap.data()?['marks'] ?? {});
      if (done) {
        if (marks.containsKey(key)) return;
        marks[key] = {
          'uid': uid,
          'name': (await me.get()).data()?['name'] ?? '',
          'at': Timestamp.now()
        };
      } else {
        final old = marks[key] as Map<String, dynamic>?;
        if (old == null) return;
        final owner = (await group(id).get()).data()?['owner'];
        if (old['uid'] != uid && owner != uid) {
          throw StateError('Yalnızca kendi işaretinizi geri alabilirsiniz.');
        }
        marks.remove(key);
      }
      tx.set(ref, {
        'marks': marks,
        'lastKey': key,
        'updatedAt': FieldValue.serverTimestamp()
      });
    });
  }

  Future<void> nextPrivateRound(String id, int currentRound) async {
    await db.runTransaction((tx) async {
      final ref = group(id);
      final snap = await tx.get(ref);
      if (snap.data()?['owner'] != uid ||
          snap.data()?['round'] != currentRound) {
        throw StateError('Yeni hatmi yalnızca kurucu başlatabilir.');
      }
      tx.update(ref, {
        'round': currentRound + 1,
        'completedHatims': FieldValue.increment(1),
        'lastCompletedAt': FieldValue.serverTimestamp()
      });
    });
  }

  Future<ReadingSession> startReading() async {
    final current = await state.get();
    if (!current.exists) {
      throw StateError(
          'Ortak hatim henüz başlatılmadı. Kurulum yönergelerine bakın.');
    }
    final round = current.data()!['round'] as int;
    final myData = (await me.get()).data() ?? {};
    final myRound = myData['activeRound'] as int?;
    final myChunk = myData['activeChunk'] as int?;
    if (myRound == round && myChunk != null) {
      try {
        final snap = await chunk(round, myChunk).get();
        final d = snap.data();
        if (d != null &&
            d['owner'] == uid &&
            (d['leaseUntil'] as Timestamp).toDate().isAfter(DateTime.now()) &&
            (d['next'] as int) < min(verseCount, (myChunk + 1) * chunkSize)) {
          return ReadingSession(round, myChunk, d['next'] as int);
        }
      } on FirebaseException catch (e) {
        // The old chunk may already belong to another reader after its lease expired.
        if (e.code != 'permission-denied') rethrow;
      }
    }
    // The expired query has a limit: one tap does not scan all 624 chunks.
    final expired = await db
        .collection('publicRounds/$round/chunks')
        .where('done', isEqualTo: false)
        .where('leaseUntil', isLessThan: Timestamp.now())
        .limit(3)
        .get();
    for (final doc in expired.docs) {
      final d = doc.data();
      if ((d['next'] as int) >=
          min(verseCount, ((d['index'] as int) + 1) * chunkSize)) continue;
      try {
        return await db.runTransaction((tx) async {
          final latest = await tx.get(doc.reference);
          final value = latest.data()!;
          if ((value['leaseUntil'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now())) throw StateError('Aralık alındı.');
          final until = Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 30)));
          tx.update(doc.reference, {'owner': uid, 'leaseUntil': until});
          tx.update(me, {'activeRound': round, 'activeChunk': value['index']});
          return ReadingSession(
              round, value['index'] as int, value['next'] as int);
        });
      } catch (_) {/* Try the next expired chunk. */}
    }
    return db.runTransaction((tx) async {
      final snap = await tx.get(state);
      final d = snap.data()!;
      if (d['round'] != round) {
        throw StateError('Yeni hatim başladı. Yeniden deneyin.');
      }
      final index = d['nextChunk'] as int;
      if (index >= chunkCount) {
        throw StateError(
            'Şu anda bütün ayetler ayrılmış. Biraz sonra tekrar deneyin.');
      }
      final ref = chunk(round, index);
      final until =
          Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30)));
      tx.set(ref, {
        'index': index,
        'next': index * chunkSize,
        'end': min(verseCount, (index + 1) * chunkSize),
        'owner': uid,
        'leaseUntil': until,
        'done': false
      });
      tx.update(state, {'nextChunk': index + 1});
      tx.update(me, {'activeRound': round, 'activeChunk': index});
      return ReadingSession(round, index, index * chunkSize);
    });
  }

  Future<ReadingSession?> confirm(ReadingSession session) async {
    final ref = chunk(session.round, session.chunk);
    return db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final status = await tx.get(state);
      final d = snap.data();
      if (d == null ||
          d['owner'] != uid ||
          (d['leaseUntil'] as Timestamp).toDate().isBefore(DateTime.now())) {
        throw StateError('Okuma süreniz doldu. Yeniden katılın.');
      }
      final next = d['next'] as int;
      if (next != session.next) {
        if (next == session.next + 1) {
          return ReadingSession(session.round, session.chunk, next);
        }
        throw StateError('Oturum değişti. Yeniden katılın.');
      }
      final end = session.end;
      if (next >= end) return null;
      final newNext = next + 1;
      final until =
          Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30)));
      final page = quran.verses[next].page;
      final pageVerses = quran.indicesForPage(page);
      final pageEnd = pageVerses.last + 1;
      var pageComplete = false;
      if (newNext == min(end, pageEnd)) {
        pageComplete = true;
        for (var index = pageVerses.first ~/ chunkSize;
            index <= pageVerses.last ~/ chunkSize;
            index++) {
          if (index == session.chunk) continue;
          if (index >= (status.data()?['nextChunk'] as int)) {
            pageComplete = false;
            break;
          }
          final other = await tx.get(chunk(session.round, index));
          if ((other.data()?['next'] as int? ?? 0) <
              min(pageEnd, (index + 1) * chunkSize)) {
            pageComplete = false;
            break;
          }
        }
      }
      final pageRecorded =
          List<int>.from(status.data()?['completedPages'] ?? []).contains(page);
      final stateUpdate = <String, dynamic>{};
      if (pageComplete &&
          !pageRecorded &&
          !(newNext == end &&
              (status.data()?['completedChunks'] as int) == chunkCount - 1)) {
        stateUpdate.addAll({
          'completedPages': FieldValue.arrayUnion([page]),
          'lastCompletedPage': page
        });
      }
      if (newNext == end) {
        final value = status.data()!;
        if (value['round'] != session.round) {
          throw StateError('Yeni hatim başladı.');
        }
        final count = value['completedChunks'] as int;
        if (count == chunkCount - 1) {
          stateUpdate.addAll({
            'round': session.round + 1,
            'nextChunk': 0,
            'completedChunks': 0,
            'completedHatims': FieldValue.increment(1),
            'lastCompletedChunk': session.chunk,
            'completedPages': <int>[],
            'lastCompletedPage': 0
          });
        } else {
          stateUpdate.addAll({
            'completedChunks': count + 1,
            'lastCompletedChunk': session.chunk
          });
        }
        tx.update(me, {
          'activeRound': FieldValue.delete(),
          'activeChunk': FieldValue.delete()
        });
        tx.update(ref, {'next': newNext, 'leaseUntil': until, 'done': true});
        tx.update(state, stateUpdate);
        return null;
      }
      tx.update(ref, {'next': newNext, 'leaseUntil': until});
      if (stateUpdate.isNotEmpty) tx.update(state, stateUpdate);
      return ReadingSession(session.round, session.chunk, newNext);
    });
  }
}
