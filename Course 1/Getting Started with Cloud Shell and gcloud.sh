#Getting Started with Cloud Shell and gcloud

#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e
echo "=== Step 1: Configuring Environment Variables ==="
# Retrieve and set the project ID and default zone/region from gcloud config

gcloud auth login --no-launch-browser
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=${ZONE%-*}
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

#read -p "Enter REGION: " REGION
#export REGION
#read -p "Enter ZONE: " ZONE
#export ZONE

# Apply configuration changes
#gcloud config set compute/region $REGION
#gcloud config set compute/zone $ZONE

echo "PROJECT ID: $PROJECT_ID"
echo "REGION: $REGION"
echo "ZONE: $ZONE"

echo "=== Step 2: Creating Virtual Machine (gcelab2) ==="
gcloud compute instances create gcelab2 \
    --machine-type=e2-medium \
    --zone=$ZONE

echo "=== Step 3: Adding Tags and Firewall Rule for Nginx ==="
# Add network tags to allow HTTP/HTTPS traffic targeting
gcloud compute instances add-tags gcelab2 --tags http-server,https-server

# Create firewall rule to allow incoming HTTP traffic on port 80
gcloud compute firewall-rules create default-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

echo "=== Step 4: Verifying Deployment & Logs ==="
# Fetch the external IP of gcelab2 and test connectivity
EXTERNAL_IP=$(gcloud compute instances list --filter="name=gcelab2" --format='value(EXTERNAL_IP)')
echo "Testing HTTP connection to http://$EXTERNAL_IP ..."
curl -I http://$EXTERNAL_IP

# Read logs for the specific virtual machine instance
echo "=== Step 5: Reading System Logs for gcelab2 ==="
gcloud logging read "resource.type=gce_instance AND labels.instance_name=gcelab2" --limit 5

echo "=== Lab Script Execution Completed Successfully! ==="
