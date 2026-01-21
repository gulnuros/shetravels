#!/usr/bin/env node

/**
 * Upload local JSON data to Firestore
 * Run this script to populate your database with the content from assets/data/
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'she-travels-5578a'
});

const db = admin.firestore();

async function uploadData() {
  console.log('🚀 Starting data upload to Firestore...\n');

  try {
    // 1. Upload Events
    console.log('📅 Uploading events...');
    const eventsData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../assets/data/local_events.json'), 'utf8')
    );

    for (const event of eventsData) {
      await db.collection('events').add({
        title: event.title,
        description: event.description,
        date: event.date,
        location: event.location,
        imageUrl: '', // Images need to be uploaded to Firebase Storage separately
        price: 350, // Default price
        availableSlots: 15,
        subscribedUsers: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: 'admin'
      });
      console.log(`  ✅ ${event.title}`);
    }

    // 2. Upload Memories
    console.log('\n💭 Uploading memories...');
    const memoriesData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../assets/data/memories.json'), 'utf8')
    );

    for (const memory of memoriesData) {
      await db.collection('memories').add({
        title: memory.title,
        description: memory.description,
        imageUrl: '', // Images need to be uploaded to Firebase Storage separately
        location: '',
        category: 'Adventure',
        createdAt: admin.firestore.Timestamp.now()
      });
      console.log(`  ✅ ${memory.title}`);
    }

    // 3. Upload Gallery
    console.log('\n🖼️  Uploading gallery items...');
    const galleryData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../assets/data/gallery.json'), 'utf8')
    );

    for (const item of galleryData) {
      await db.collection('gallery').add({
        title: item.title,
        description: item.description || '',
        imageUrl: '', // Images need to be uploaded to Firebase Storage separately
        category: 'Adventures',
        createdAt: admin.firestore.Timestamp.now()
      });
      console.log(`  ✅ ${item.title}`);
    }

    // 4. Create Founder Message
    console.log('\n👤 Creating founder message...');
    await db.collection('founderMessages').add({
      name: 'Alexa',
      title: 'Founder & CEO',
      message: 'Welcome to SheTravels! Our mission is to empower women through transformative travel experiences. Join us on adventures that inspire, connect, and celebrate the spirit of exploration.',
      imageUrl: '', // Upload aleksa_portrait.png via admin panel
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });
    console.log('  ✅ Founder message created');

    console.log('\n🎉 Data upload complete!');
    console.log('\n📝 Summary:');
    console.log(`   - ${eventsData.length} events uploaded`);
    console.log(`   - ${memoriesData.length} memories uploaded`);
    console.log(`   - ${galleryData.length} gallery items uploaded`);
    console.log(`   - 1 founder message created`);
    console.log('\n⚠️  Note: Image URLs are empty. Upload images via admin panel at:');
    console.log('   https://she-travels-5578a.web.app/admin-login');
    console.log('\n✅ Your website should now show content!');
    console.log('   Visit: https://she-travels-5578a.web.app');

  } catch (error) {
    console.error('❌ Error uploading data:', error);
    process.exit(1);
  }

  process.exit(0);
}

uploadData();
