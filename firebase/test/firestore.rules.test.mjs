// Security-rule tests for firebase/firestore.rules (decisions D-008, D-009).
// Run with `npm test` in this folder; it starts the Firestore emulator.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-testacer',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'allowlist/admin@example.com'), { role: 'admin' });
    await setDoc(doc(db, 'allowlist/learner@example.com'), { role: 'learner' });
    await setDoc(doc(db, 'questionSets/set1'), { title: 'Gyakorló teszt' });
    await setDoc(doc(db, 'questionSets/set1/questions/q1'), { order: 1 });
    await setDoc(doc(db, 'users/learner-uid'), { email: 'learner@example.com' });
    await setDoc(doc(db, 'users/learner-uid/progress/set1'), { items: {} });
  });
});

/** A user signed in with Google (e-mail always verified). */
const googleUser = (uid, email) =>
  env
    .authenticatedContext(uid, {
      email,
      email_verified: true,
      firebase: { sign_in_provider: 'google.com' },
    })
    .firestore();

/** A user with the e-mail/password provider (password or e-mail link). */
const passwordUser = (uid, email, verified) =>
  env
    .authenticatedContext(uid, {
      email,
      email_verified: verified,
      firebase: { sign_in_provider: 'password' },
    })
    .firestore();

describe('signed out', () => {
  test('cannot read anything', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'allowlist/learner@example.com')));
    await assertFails(getDoc(doc(db, 'questionSets/set1')));
    await assertFails(getDoc(doc(db, 'users/learner-uid')));
  });
});

describe('invited learner', () => {
  const db = () => googleUser('learner-uid', 'learner@example.com');

  test('reads its own allowlist entry, but cannot list the allowlist', async () => {
    await assertSucceeds(getDoc(doc(db(), 'allowlist/learner@example.com')));
    await assertFails(getDocs(collection(db(), 'allowlist')));
  });

  test('reads question sets and questions, but cannot change them', async () => {
    await assertSucceeds(getDoc(doc(db(), 'questionSets/set1')));
    await assertSucceeds(getDocs(collection(db(), 'questionSets/set1/questions')));
    await assertFails(setDoc(doc(db(), 'questionSets/set1'), { title: 'x' }));
  });

  test('reads and writes its own profile and progress only', async () => {
    await assertSucceeds(setDoc(doc(db(), 'users/learner-uid'), { activeSetId: 'set1' }));
    await assertSucceeds(
      setDoc(doc(db(), 'users/learner-uid/progress/set1'), { items: { a: { box: 1 } } }),
    );
    await assertFails(getDoc(doc(db(), 'users/someone-else')));
    await assertFails(setDoc(doc(db(), 'users/someone-else/progress/set1'), { items: {} }));
  });

  test('cannot invite anyone', async () => {
    await assertFails(setDoc(doc(db(), 'allowlist/friend@example.com'), { role: 'learner' }));
  });
});

describe('admin', () => {
  const db = () => googleUser('admin-uid', 'admin@example.com');

  test('lists, adds and removes invitations', async () => {
    await assertSucceeds(getDocs(collection(db(), 'allowlist')));
    await assertSucceeds(setDoc(doc(db(), 'allowlist/new@example.com'), { role: 'learner' }));
    await assertSucceeds(deleteDoc(doc(db(), 'allowlist/new@example.com')));
  });

  test('writes question sets', async () => {
    await assertSucceeds(setDoc(doc(db(), 'questionSets/set2'), { title: 'Új' }));
    await assertSucceeds(setDoc(doc(db(), 'questionSets/set2/questions/q1'), { order: 1 }));
  });

  test("cannot read other users' progress", async () => {
    await assertFails(getDoc(doc(db(), 'users/learner-uid/progress/set1')));
  });
});

describe('not invited', () => {
  const db = () => googleUser('stranger-uid', 'stranger@example.com');

  test('may check its own (missing) allowlist entry', async () => {
    await assertSucceeds(getDoc(doc(db(), 'allowlist/stranger@example.com')));
  });

  test('cannot read question sets or create a profile', async () => {
    await assertFails(getDoc(doc(db(), 'questionSets/set1')));
    await assertFails(setDoc(doc(db(), 'users/stranger-uid'), { email: 'x' }));
  });
});

describe('password accounts', () => {
  test('need a verified e-mail, even when invited', async () => {
    const unverified = passwordUser('learner-uid', 'learner@example.com', false);
    await assertFails(getDoc(doc(unverified, 'questionSets/set1')));

    const verified = passwordUser('learner-uid', 'learner@example.com', true);
    await assertSucceeds(getDoc(doc(verified, 'questionSets/set1')));
  });
});

describe('e-mail case', () => {
  test('an upper-case address in the token matches the lower-case entry', async () => {
    const db = googleUser('learner-uid', 'Learner@Example.com');
    await assertSucceeds(getDoc(doc(db, 'questionSets/set1')));
  });
});
