import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, signInAnonymously } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, doc, setDoc, getDoc, updateDoc, collection, query, where, limit, getDocs, runTransaction, Timestamp, serverTimestamp, arrayUnion, deleteField } from 'firebase/firestore';

const projectId = 'demo-hatim-halkasi';
const app = initializeApp({apiKey: 'demo-key', authDomain: `${projectId}.firebaseapp.com`, projectId, appId: '1:1234567890:android:demo'});
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', {disableWarnings: true});
const db = getFirestore(app);
connectFirestoreEmulator(db, '127.0.0.1', 8080);

const secondApp = initializeApp({apiKey: 'demo-key', authDomain: `${projectId}.firebaseapp.com`, projectId, appId: '1:1234567890:android:demo'}, 'second-reader');
const secondAuth = getAuth(secondApp);
connectAuthEmulator(secondAuth, 'http://127.0.0.1:9099', {disableWarnings: true});
const secondDb = getFirestore(secondApp);
connectFirestoreEmulator(secondDb, '127.0.0.1', 8080);

const state = doc(db, 'public/state');
const chunk = doc(db, 'publicRounds/1/chunks/0');

async function seedState() {
  const response = await fetch(`http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents/public/state`, {
    method: 'PATCH', headers: {'Authorization': 'Bearer owner', 'Content-Type': 'application/json'},
    body: JSON.stringify({fields: {
      round: {integerValue: '1'}, nextChunk: {integerValue: '0'}, completedChunks: {integerValue: '0'},
      completedHatims: {integerValue: '0'}, lastCompletedChunk: {integerValue: '-1'},
    }}),
  });
  assert.equal(response.status, 200, await response.text());
}

await seedState();
const credential = await signInAnonymously(auth);
const uid = credential.user.uid;
const me = doc(db, 'users', uid);
await setDoc(me, {name: 'Deneme', createdAt: serverTimestamp(), groups: []});
console.log('Anonymous user created');

const expired = await getDocs(query(collection(db, 'publicRounds/1/chunks'),
  where('done', '==', false), where('leaseUntil', '<', Timestamp.now()), limit(3)));
assert.equal(expired.size, 0);
console.log('Expired chunk query allowed');

await runTransaction(db, async (tx) => {
  const current = await tx.get(state);
  const index = current.get('nextChunk');
  const until = Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000));
  tx.set(chunk, {index, next: 0, end: 10, owner: uid, leaseUntil: until, done: false});
  tx.update(state, {nextChunk: index + 1});
  tx.update(me, {activeRound: 1, activeChunk: 0});
});
assert.equal((await getDoc(chunk)).get('owner'), uid);
console.log('First chunk allocated');

await runTransaction(db, async (tx) => {
  const current = await tx.get(chunk);
  tx.update(chunk, {next: current.get('next') + 1,
    leaseUntil: Timestamp.fromDate(new Date(Date.now() + 2 * 1000))});
});
assert.equal((await getDoc(chunk)).get('next'), 1);
console.log('First verse confirmed');

await assert.rejects(
  updateDoc(state, {completedPages: arrayUnion(1), lastCompletedPage: 1}),
  (error) => error.code === 'permission-denied',
);
console.log('Premature page completion rejected');

const secondCredential = await signInAnonymously(secondAuth);
const secondUid = secondCredential.user.uid;
const secondMe = doc(secondDb, 'users', secondUid);
await setDoc(secondMe, {name: 'İkinci Okuyucu', createdAt: serverTimestamp(), groups: []});
await new Promise((resolve) => setTimeout(resolve, 2500));
const available = await getDocs(query(collection(secondDb, 'publicRounds/1/chunks'),
  where('done', '==', false), where('leaseUntil', '<', Timestamp.now()), limit(3)));
assert.equal(available.size, 1);
await runTransaction(secondDb, async (tx) => {
  const expiredChunk = await tx.get(doc(secondDb, available.docs[0].ref.path));
  assert.equal(expiredChunk.get('next'), 1);
  tx.update(expiredChunk.ref, {
    owner: secondUid,
    leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000)),
  });
  tx.update(secondMe, {activeRound: 1, activeChunk: 0});
});
const resumed = await getDoc(doc(secondDb, chunk.path));
assert.equal(resumed.get('owner'), secondUid);
assert.equal(resumed.get('next'), 1);
console.log('Second anonymous user resumed from the first user\'s next unconfirmed verse');

for (let next = 2; next <= 10; next++) {
  await runTransaction(secondDb, async (tx) => {
    const current = await tx.get(doc(secondDb, chunk.path));
    const status = await tx.get(doc(secondDb, state.path));
    assert.equal(current.get('next'), next - 1);
    if (next === 7) {
      tx.update(doc(secondDb, state.path), {
        completedPages: arrayUnion(1), lastCompletedPage: 1,
      });
    }
    if (next === 10) {
      tx.update(doc(secondDb, state.path), {
        completedChunks: status.get('completedChunks') + 1,
        lastCompletedChunk: 0,
      });
      tx.update(secondMe, {activeRound: deleteField(), activeChunk: deleteField()});
    }
    tx.update(doc(secondDb, chunk.path), {
      next, done: next === 10,
      leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000)),
    });
  });
}
assert.deepEqual((await getDoc(doc(secondDb, state.path))).get('completedPages'), [1]);
assert.equal((await getDoc(doc(secondDb, state.path))).get('completedChunks'), 1);
console.log('First fully confirmed page appears in the one-document map');

const nextChunk = doc(secondDb, 'publicRounds/1/chunks/1');
await runTransaction(secondDb, async (tx) => {
  const current = await tx.get(doc(secondDb, state.path));
  assert.equal(current.get('nextChunk'), 1);
  tx.set(nextChunk, {index: 1, next: 10, end: 20, owner: secondUid,
    leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000)), done: false});
  tx.update(doc(secondDb, state.path), {nextChunk: 2});
  tx.update(secondMe, {activeRound: 1, activeChunk: 1});
});
for (let next = 11; next <= 12; next++) {
  await runTransaction(secondDb, async (tx) => {
    const current = await tx.get(nextChunk);
    const status = await tx.get(doc(secondDb, state.path));
    assert.equal(current.get('next'), next - 1);
    if (next === 12) {
      const previous = await tx.get(doc(secondDb, chunk.path));
      assert.equal(previous.get('next'), 10);
      tx.update(doc(secondDb, state.path), {
        completedPages: arrayUnion(2), lastCompletedPage: 2,
      });
    }
    tx.update(nextChunk, {next,
      leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000))});
  });
}
assert.deepEqual((await getDoc(doc(secondDb, state.path))).get('completedPages'), [1, 2]);
console.log('Page spanning two allocations turns green after both are confirmed');

await deleteApp(secondApp);
await deleteApp(app);
process.exit(0);
