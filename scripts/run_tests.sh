#!/usr/bin/env bash
set -e

echo "🧪  Running Flutter tests"
flutter test

echo "🧪  Running Python backend tests"
pytest backend
