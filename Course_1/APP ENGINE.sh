#APP ENGINE

#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e
# ==========================================
# CONFIGURATION VARIABLES
# ==========================================
#read -p "Enter Region: " REGION
# Automatically fetch the active GCP Project ID from your session

gcloud auth login --no-launch-browser
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=${ZONE%-*}

gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "Using Project ID: $PROJECT_ID"
echo "Using Region:     $REGION"

# ==========================================
# TASK 1: Enable Google App Engine Admin API
# ==========================================
echo "==> Enabling App Engine Admin API..."
gcloud services enable appengine.googleapis.com --project="$PROJECT_ID"

# ==========================================
# TASK 2: Download and Setup the Hello World App
# ==========================================
echo "==> Cloning Python docs samples repository..."
if [ -d "python-docs-samples" ]; then
    echo "Directory python-docs-samples already exists. Pulling latest changes..."
    cd python-docs-samples
    git pull
    cd ../
else
    git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
fi

echo "==> Navigating to the sample code directory..."
cd python-docs-samples/appengine/standard_python3/hello_world

echo "==> Setting up Python virtual environment..."
sudo apt update
sudo apt install -y python3-venv
python3 -m venv myenv
source myenv/bin/activate

# ==========================================
# TASK 4: Make a change (Update message)
# ==========================================
echo "==> Updating main.py to say 'Hello, Cruel World!'..."
# Using Python/sed to safely replace the text without manual nano intervention
python3 -c '
with open("main.py", "r") as f:
    content = f.read()
content = content.replace("Hello World!", "Hello, Cruel World!")
with open("main.py", "w") as f:
    f.write(content)
'

# ==========================================
# TASK 5: Deploy the App to App Engine
# ==========================================
echo "==> Deploying app to App Engine (Region: $REGION)..."
# gcloud app deploy automatically creates the app in the specified region if it doesn't exist
gcloud app deploy app.yaml --region="$REGION" --quiet

# ==========================================
# TASK 6: View Application Details
# ==========================================
echo "==> Deployment complete! Fetching application details..."
gcloud app browse
