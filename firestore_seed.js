/**
 * FieldAgent — Firestore Seed Script
 * Run once to populate: villages/ and patients/ collections
 *
 * Usage:
 *   node firestore_seed.js
 *
 * Requirements:
 *   npm install firebase-admin
 *   Place your serviceAccountKey.json in this folder
 *   (Download from Firebase Console → Project Settings → Service Accounts)
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seed() {
  console.log('🌱 Seeding Firestore for FieldAgent...\n');

  // ── Villages ──────────────────────────────────────────────
  const villages = ['Rampura', 'Sitapur', 'Govindpur', 'Krishnanagar'];
  for (const v of villages) {
    await db.collection('villages').doc(v.toLowerCase()).set({ name: v });
    console.log(`✅ Village: ${v}`);
  }

  // ── Patients ──────────────────────────────────────────────
  const patients = [
    { id: 'p001', name: 'Sunita Devi',  age: 24, village: 'Rampura',      anc_number: 'ANC-2024-001', lmp_date: '2024-09-15', edd: '2025-06-22' },
    { id: 'p002', name: 'Meena Kumari', age: 28, village: 'Sitapur',      anc_number: 'ANC-2024-002', lmp_date: '2024-10-01', edd: '2025-07-08' },
    { id: 'p003', name: 'Priya Sharma', age: 22, village: 'Govindpur',    anc_number: 'ANC-2024-003', lmp_date: '2024-08-20', edd: '2025-05-27' },
    { id: 'p004', name: 'Radha Yadav',  age: 31, village: 'Rampura',      anc_number: 'ANC-2024-004', lmp_date: '2024-11-10', edd: '2025-08-17' },
    { id: 'p005', name: 'Anita Patel',  age: 26, village: 'Krishnanagar', anc_number: 'ANC-2024-005', lmp_date: '2024-09-28', edd: '2025-07-05' },
  ];

  for (const p of patients) {
    await db.collection('patients').doc(p.id).set({
      ...p,
      created_at: new Date().toISOString(),
    });
    console.log(`✅ Patient: ${p.name} (${p.village})`);
  }

  console.log('\n🎉 Firestore seed complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
