#A Tour of Google Cloud Hands-on Labs

#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e
# ==========================================
# CONFIGURATION VARIABLES
# ==========================================
#gcloud auth login --no-launch-browser
#export PROJECT_ID=$(gcloud config get-value project)
#export ZONE=$(gcloud compute project-info describe
#\ --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
#export REGION=${ZONE%-*}

read -p "Enter Project ID: " PROJECT_ID
export LOCATION="us-west4"
export ZONE="us-west4-b"

echo "Configuring gcloud defaults..."
gcloud config set project $PROJECT_ID
#gcloud config set region $REGION
#gcloud config set zone $ZONE

# ==========================================
# TASK 3: REVIEW ROLES AND PERMISSIONS
# ==========================================
echo "Viewing current IAM policies and roles for the project..."
gcloud projects get-iam-policy "$PROJECT_ID"

# ==========================================
# TASK 4: ENABLE APIS AND SERVICES
# ==========================================
echo "Enabling the Dialogflow API..."
gcloud services enable dialogflow.googleapis.com

# ==========================================
# TASK 5: CREATE A PUB/SUB TOPIC
# ==========================================
TOPIC_ID="my-topic"

echo "Creating Cloud Pub/Sub topic: $TOPIC_ID..."
gcloud pubsub topics create "$TOPIC_ID"

echo "Verifying the created Pub/Sub topic..."
gcloud pubsub topics describe "$TOPIC_ID"

echo "All lab tasks completed successfully!"
