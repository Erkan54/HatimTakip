import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase/app';
import {getAuth, connectAuthEmulator, signInAnonymously} from 'firebase/auth';
import {getFirestore, connectFirestoreEmulator, doc, getDoc, runTransaction,
  Timestamp, arrayUnion} from 'firebase/firestore';

const projectId = 'demo-hatim-halkasi';
const app = initializeApp({apiKey: 'demo-key', authDomain: `${projectId}.firebaseapp.com`,
  projectId, appId: '1:1234567890:android:demo'}, 'edge-case');
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', {disableWarnings: true});
const db = getFirestore(app);
connectFirestoreEmulator(db, '127.0.0.1', 8080);
const uid = (await signInAnonymously(auth)).user.uid;

async function seed(path, fields) {
  const response = await fetch(`http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents/${path}`, {
    method: 'PATCH', headers: {Authorization: 'Bearer owner', 'Content-Type': 'application/json'},
    body: JSON.stringify({fields}),
  });
  assert.equal(response.status, 200, await response.text());
}
const integerValue = (value) => ({integerValue: String(value)});
const leaseUntil = {timestampValue: new Date(Date.now() + 30 * 60 * 1000).toISOString()};
await seed('public/state', {
  round: integerValue(1), nextChunk: integerValue(623), completedChunks: integerValue(622),
  completedHatims: integerValue(0), lastCompletedChunk: integerValue(621),
  completedPages: {arrayValue: {values: Array.from({length: 602}, (_, i) => integerValue(i + 1))}},
  lastCompletedPage: integerValue(602),
});
for (const index of [620, 621, 622]) {
  await seed(`publicRounds/1/chunks/${index}`, {
    index: integerValue(index), next: integerValue(index === 622 ? 6220 : (index + 1) * 10),
    end: integerValue((index + 1) * 10), owner: {stringValue: index === 622 ? uid : 'other'},
    leaseUntil, done: {booleanValue: index !== 622},
  });
}

const state = doc(db, 'public/state');
const chunk = doc(db, 'publicRounds/1/chunks/622');
await runTransaction(db, async (tx) => {
  const current = await tx.get(chunk);
  const status = await tx.get(state);
  assert.equal(current.get('next'), 6220);
  assert.equal(status.get('completedPages').length, 602);
  for (const index of [620, 621]) {
    const previous = await tx.get(doc(db, `publicRounds/1/chunks/${index}`));
    assert.equal(previous.get('next'), (index + 1) * 10);
  }
  tx.update(chunk, {next: 6221,
    leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000))});
  tx.update(state, {completedPages: arrayUnion(603), lastCompletedPage: 603});
});
assert.equal((await getDoc(state)).get('completedPages').length, 603);
console.log('The 603rd page was securely completed with a 603-entry overview');

await seed('public/state', {
  round: integerValue(1), nextChunk: integerValue(580), completedChunks: integerValue(579),
  completedHatims: integerValue(0), lastCompletedChunk: integerValue(578),
  completedPages: {arrayValue: {values: Array.from({length: 584}, (_, i) => integerValue(i + 1))}},
  lastCompletedPage: integerValue(584),
});
for (const index of [575, 576, 577, 578, 579]) {
  await seed(`publicRounds/1/chunks/${index}`, {
    index: integerValue(index), next: integerValue(index === 579 ? 5799 : (index + 1) * 10),
    end: integerValue((index + 1) * 10), owner: {stringValue: index === 579 ? uid : 'other'},
    leaseUntil, done: {booleanValue: index !== 579},
  });
}
const longPageChunk = doc(db, 'publicRounds/1/chunks/579');
await runTransaction(db, async (tx) => {
  const current = await tx.get(longPageChunk);
  const status = await tx.get(state);
  assert.equal(current.get('next'), 5799);
  assert.equal(status.get('completedPages').length, 584);
  for (const index of [575, 576, 577, 578]) {
    const previous = await tx.get(doc(db, `publicRounds/1/chunks/${index}`));
    assert.equal(previous.get('next'), (index + 1) * 10);
  }
  tx.update(longPageChunk, {next: 5800, done: true,
    leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000))});
  tx.update(state, {completedChunks: 580, lastCompletedChunk: 579,
    completedPages: arrayUnion(585), lastCompletedPage: 585});
});
assert.equal((await getDoc(state)).get('completedPages').length, 585);
console.log('A page spanning five allocations was recorded with its last completed allocation');

await seed('public/state', {
  round: integerValue(1), nextChunk: integerValue(624), completedChunks: integerValue(623),
  completedHatims: integerValue(0), lastCompletedChunk: integerValue(622),
  completedPages: {arrayValue: {values: Array.from({length: 603}, (_, i) => integerValue(i + 1))}},
  lastCompletedPage: integerValue(603),
});
await seed('publicRounds/1/chunks/623', {
  index: integerValue(623), next: integerValue(6235), end: integerValue(6236),
  owner: {stringValue: uid}, leaseUntil, done: {booleanValue: false},
});
const finalChunk = doc(db, 'publicRounds/1/chunks/623');
await runTransaction(db, async (tx) => {
  const current = await tx.get(finalChunk);
  const status = await tx.get(state);
  assert.equal(current.get('next'), 6235);
  assert.equal(status.get('completedChunks'), 623);
  tx.update(finalChunk, {next: 6236, done: true,
    leaseUntil: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000))});
  tx.update(state, {round: 2, nextChunk: 0, completedChunks: 0,
    completedHatims: 1, lastCompletedChunk: 623, completedPages: [], lastCompletedPage: 0});
});
const newRound = await getDoc(state);
assert.equal(newRound.get('round'), 2);
assert.deepEqual(newRound.get('completedPages'), []);
console.log('The 624th allocation resets the map for the next shared hatim');
await deleteApp(app);
process.exit(0);
