// Runs only against the local demo project. No production credentials or reads.
import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase/app';
import {getAuth, connectAuthEmulator, signInAnonymously} from 'firebase/auth';
import {getFirestore, connectFirestoreEmulator, doc, setDoc, updateDoc, getDoc, serverTimestamp} from 'firebase/firestore';

const apps = [];
async function reader(name) {
  const app = initializeApp({apiKey:'demo-key', projectId:'demo-hatim-halkasi', appId:'1:1:android:demo'}, name);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', {disableWarnings:true});
  const db = getFirestore(app);
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  const {user} = await signInAnonymously(auth);
  const profile = doc(db, 'users', user.uid);
  await setDoc(profile, {name, createdAt:serverTimestamp(), groups:[]});
  return {db, profile};
}

try {
  const owner = await reader('profile-owner');
  const stranger = await reader('profile-stranger');
  await updateDoc(owner.profile, {name:'Yeni ad'});
  assert.equal((await getDoc(owner.profile)).get('name'), 'Yeni ad');
  for (const bad of [{name:''}, {name:'x'.repeat(41)}, {name:123}, {createdAt:serverTimestamp()}, {admin:true}]) {
    await assert.rejects(updateDoc(owner.profile, bad), e => e.code === 'permission-denied');
  }
  await assert.rejects(updateDoc(doc(stranger.db, owner.profile.path), {name:'Sahte ad'}),
    e => e.code === 'permission-denied');
  const final = await getDoc(owner.profile);
  assert.equal(final.get('name'), 'Yeni ad');
  assert.deepEqual(final.get('groups'), []);
  console.log('PASS: own valid rename; invalid names, immutable fields and other users denied.');
} finally {
  await Promise.all(apps.map(app => deleteApp(app)));
}
