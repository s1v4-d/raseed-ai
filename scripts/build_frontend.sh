#!/usr/bin/env bash
set -e

echo "🏗️  Building Flutter web app"
cd frontend
flutter pub get
flutter build web --release
cd ..

echo "📦  Copying Flutter build to hosting directory"
mkdir -p build/web
cp -r frontend/build/web/* build/web/

echo "🚀  Deploying to Firebase Hosting (using ADC)"
# Firebase CLI will automatically use Application Default Credentials
# No FIREBASE_TOKEN needed
firebase use ${PROJECT_ID:-$GOOGLE_CLOUD_PROJECT}
firebase deploy --only hosting
