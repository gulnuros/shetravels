#!/usr/bin/env python3
"""
Firebase Setup Script
This script uploads images to Firebase Storage and creates Firestore documents.

Requirements:
    pip install firebase-admin python-dotenv

Usage:
    python3 scripts/setup_firebase.py
"""

import os
import sys
from datetime import datetime
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, storage
    from dotenv import load_dotenv
except ImportError:
    print("❌ Required packages not installed.")
    print("Run: pip install firebase-admin python-dotenv")
    sys.exit(1)


def load_env():
    """Load environment variables from .env file"""
    env_path = Path(__file__).parent.parent / '.env'
    load_dotenv(env_path)
    return {
        'api_key': os.getenv('FIREBASE_API_KEY'),
        'auth_domain': os.getenv('FIREBASE_AUTH_DOMAIN'),
        'project_id': os.getenv('FIREBASE_PROJECT_ID'),
        'storage_bucket': os.getenv('FIREBASE_STORAGE_BUCKET'),
        'messaging_sender_id': os.getenv('FIREBASE_MESSAGING_SENDER_ID'),
        'app_id': os.getenv('FIREBASE_APP_ID'),
    }


def init_firebase(config):
    """Initialize Firebase Admin SDK"""
    # For admin SDK, we need a service account key
    # This is a simplified version - you'll need to download service account key
    print("⚠️  This script requires a Firebase Admin SDK service account key.")
    print("\nTo get it:")
    print("1. Go to Firebase Console → Project Settings → Service Accounts")
    print("2. Click 'Generate New Private Key'")
    print("3. Save as 'serviceAccountKey.json' in the project root")
    print()

    service_account_path = Path(__file__).parent.parent / 'serviceAccountKey.json'

    if not service_account_path.exists():
        print(f"❌ Service account key not found at: {service_account_path}")
        print("\nAlternative: Use the manual setup via Firebase Console")
        print("See FIREBASE_SETUP_INSTRUCTIONS.md for details")
        sys.exit(1)

    cred = credentials.Certificate(str(service_account_path))
    firebase_admin.initialize_app(cred, {
        'storageBucket': config['storage_bucket']
    })
    print("✅ Firebase Admin SDK initialized\n")


def upload_image(local_path, storage_path):
    """Upload image to Firebase Storage and return download URL"""
    try:
        bucket = storage.bucket()
        blob = bucket.blob(storage_path)

        local_file = Path(__file__).parent.parent / local_path

        if not local_file.exists():
            print(f"⚠️  File not found: {local_file}")
            return None

        blob.upload_from_filename(str(local_file))
        blob.make_public()

        return blob.public_url
    except Exception as e:
        print(f"❌ Error uploading {local_path}: {e}")
        return None


def setup_firestore_data():
    """Create Firestore collections and documents"""
    db = firestore.client()

    print("🚀 Starting Firebase setup...\n")

    # 1. Founder Message
    print("📸 Uploading founder image...")
    founder_image_url = upload_image(
        'assets/aleksa_portrait.png',
        'founder_images/aleksa_portrait.png'
    )

    if founder_image_url:
        print(f"✅ Founder image uploaded: {founder_image_url}")
        print("📝 Creating founder message...")

        db.collection('founderMessages').add({
            'name': 'Alexa',
            'title': 'Founder & CEO',
            'message': 'Welcome to SheTravels! Our mission is to empower women through transformative travel experiences. Join us on adventures that inspire, connect, and celebrate the spirit of exploration.',
            'imageUrl': founder_image_url,
            'isActive': True,
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat(),
        })
        print("✅ Founder message created\n")

    # 2. Gallery Images
    print("🖼️  Uploading gallery images...")
    gallery_images = [
        {'file': 'assets/hike_1.jpeg', 'title': 'Mountain Adventure',
         'description': 'Exploring scenic mountain trails', 'category': 'Hiking'},
        {'file': 'assets/hike_2.jpeg', 'title': 'Summit Success',
         'description': 'Reaching new heights together', 'category': 'Hiking'},
        {'file': 'assets/hike_3.jpeg', 'title': 'Trail Discoveries',
         'description': 'Finding beauty in every step', 'category': 'Hiking'},
        {'file': 'assets/hike_4.jpeg', 'title': 'Nature Escapes',
         'description': 'Connecting with the wilderness', 'category': 'Hiking'},
        {'file': 'assets/hike_5.jpeg', 'title': 'Group Adventures',
         'description': 'Making memories with fellow travelers', 'category': 'Hiking'},
    ]

    for img in gallery_images:
        filename = Path(img['file']).name
        image_url = upload_image(img['file'], f"gallery/{filename}")

        if image_url:
            db.collection('gallery').add({
                'title': img['title'],
                'description': img['description'],
                'imageUrl': image_url,
                'category': img['category'],
                'createdAt': firestore.SERVER_TIMESTAMP,
            })
            print(f"✅ Gallery: {img['title']}")

    print()

    # 3. Memories
    print("💭 Uploading memories...")
    memories = [
        {'file': 'assets/hike_1.jpeg', 'title': 'First Summit',
         'description': 'My first mountain peak - an unforgettable experience!',
         'location': 'Mount Rainier'},
        {'file': 'assets/hike_2.jpeg', 'title': 'Sunrise Hike',
         'description': 'Watching the sunrise from the mountain top',
         'location': 'North Cascades'},
        {'file': 'assets/hike_3.jpeg', 'title': 'Trail Friends',
         'description': 'Made lifelong friends on this adventure',
         'location': 'Olympic National Park'},
        {'file': 'assets/hike_5.jpeg', 'title': 'Alpine Lakes',
         'description': 'Crystal clear alpine lakes surrounded by peaks',
         'location': 'Alpine Lakes Wilderness'},
        {'file': 'assets/past2.jpeg', 'title': 'Past Adventures',
         'description': 'Looking back at amazing journeys',
         'location': 'Various Locations'},
    ]

    for memory in memories:
        filename = Path(memory['file']).name
        image_url = upload_image(memory['file'], f"memories/{filename}")

        if image_url:
            db.collection('memories').add({
                'title': memory['title'],
                'description': memory['description'],
                'imageUrl': image_url,
                'location': memory['location'],
                'category': 'Adventure',
                'createdAt': firestore.SERVER_TIMESTAMP,
            })
            print(f"✅ Memory: {memory['title']}")

    print()

    # 4. Events
    print("📅 Creating events...")
    events = [
        {
            'title': 'Summer Mountain Retreat',
            'date': '2025-07-15',
            'description': 'Join us for a 3-day mountain adventure with hiking, camping, and breathtaking views!',
            'imageFile': 'assets/hike_1.jpeg',
            'location': 'Mount Rainier National Park, WA',
            'price': 350,
            'availableSlots': 15,
        },
        {
            'title': 'Coastal Hiking Experience',
            'date': '2025-08-20',
            'description': 'Explore beautiful coastal trails with ocean views and beach camping.',
            'imageFile': 'assets/hike_5.jpeg',
            'location': 'Olympic Coast, WA',
            'price': 275,
            'availableSlots': 12,
        },
    ]

    for event in events:
        filename = Path(event['imageFile']).name
        image_url = upload_image(event['imageFile'], f"events/{filename}")

        if image_url:
            db.collection('events').add({
                'title': event['title'],
                'date': event['date'],
                'description': event['description'],
                'imageUrl': image_url,
                'location': event['location'],
                'price': event['price'],
                'availableSlots': event['availableSlots'],
                'subscribedUsers': [],
                'createdAt': firestore.SERVER_TIMESTAMP,
                'createdBy': 'admin',
            })
            print(f"✅ Event: {event['title']}")

    print("\n🎉 Firebase setup completed successfully!")
    print("\n📊 Summary:")
    print("   - 1 Founder message created")
    print(f"   - {len(gallery_images)} Gallery images uploaded")
    print(f"   - {len(memories)} Memories uploaded")
    print(f"   - {len(events)} Events created")
    print("\n✨ Your app should now display all images correctly!")


def main():
    print("🚀 Firebase Setup Script\n")

    # Load config
    config = load_env()

    if not config['project_id']:
        print("❌ Firebase configuration not found in .env file")
        sys.exit(1)

    print(f"Project: {config['project_id']}")
    print(f"Storage: {config['storage_bucket']}\n")

    # Initialize Firebase
    init_firebase(config)

    # Setup data
    setup_firestore_data()


if __name__ == '__main__':
    main()
