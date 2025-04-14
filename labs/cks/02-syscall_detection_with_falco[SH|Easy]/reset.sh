#!/bin/bash
set -e

echo "🧹 Cleaning up the lab environment..."
kubectl delete ns team-green --ignore-not-found
kubectl delete ns team-blue --ignore-not-found
kubectl delete ns team-red --ignore-not-found
kubectl delete ns falco --ignore-not-found
echo "✅ Cleanup complete."