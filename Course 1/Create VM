#Create VM

#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e
echo "=== Step 1: Configuring Environment Variables ==="

# Automatically fetch the active Project ID from your current gcloud session

gcloud auth login --no-launch-browser
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
#read -p "Enter Zone: " ZONE
export REGION=${ZONE%-*}
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

#read -p "Enter Region: " REGION
echo "Using Project ID: $PROJECT_ID"
echo "Using Region:     $REGION"
echo "Using Zone:       $ZONE"

# Set gcloud configuration defaults
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"


echo "=== Step 2: Creating the First VM Instance (gcelab) ==="
# Creating a VM instance with NGINX firewall rule enabled (analogous to Console settings)
gcloud compute instances create gcelab \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --tags=http-server

# Ensure default HTTP firewall rule exists to allow port 80 traffic
if ! gcloud compute firewall-rules describe default-allow-http &>/dev/null; then
    echo "Creating firewall rule to allow HTTP traffic..."
    gcloud compute firewall-rules create default-allow-http \
        --allow=tcp:80 \
        --target-tags=http-server \
        --description="Allow port 80 traffic for HTTP"
fi


echo "=== Step 3: Installing and Testing NGINX on gcelab via SSH ==="
# Remotely run commands via gcloud compute ssh to update OS, install NGINX, and verify
gcloud compute ssh gcelab --zone="$ZONE" --command="
    sudo apt-get update &&
    sudo apt-get install -y nginx &&
    sudo systemctl enable nginx &&
    sudo systemctl start nginx &&
    echo '--- NGINX Process Status ---' &&
    ps auwx | grep nginx
"


echo "=== Step 4: Creating the Second VM Instance (gcelab2) ==="
# Creating the second VM instance using default settings via gcloud
gcloud compute instances create gcelab2 \
    --machine-type=e2-medium \
    --zone="$ZONE"


echo "=== Lab Automation Completed Successfully! ==="
echo "You can view your active instances by running:"
echo "  gcloud compute instances list"////////////////////////////////////
