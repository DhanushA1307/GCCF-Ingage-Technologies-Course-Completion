#!/bin/bash
echo
# Choose Course Folder
choose_folder_name=("Course 1" "Course 2" "Course 3" "Course 4")

for course in "${choose_folder_name[@]}"; do
    echo "$course"
done

echo

read -p "Enter the Course Number: " choose_the_course_no
echo

# Validate Course Number
if ! [[ "$choose_the_course_no" =~ ^[0-9]+$ ]] || \
   (( choose_the_course_no < 1 || choose_the_course_no > 4 )); then
    echo "Wrong Input, Enter the Number"
    exit 1
fi

cd ~/"GCCF-Ingage-Technologies-Course-Completion"/"${choose_folder_name[${choose_the_course_no-1}]}"

# Course File Names
case "$choose_the_course_no" in

    1)
        lst=(
            "A Tour of Google Cloud Hands-on Labs"
            "Create VM"
            "APP ENGINE"
            "Deploy an Application to Google Kubernetes Engine"
            "Getting Started with Cloud Shell and gcloud"
            "Deploy a Cloud Run Function via the Command Line"
            "Deploy an Application to Google Kubernetes Engine"
        )
        ;;

    2)
        lst=(
            "Manage Cloud Storage with the Google Cloud CLI"
            "Pub/Sub Python"
            "Explore APIs in Google Cloud (all-in-one Cloud Shell script)"
            "Manage Access Control with IAM"
            "Authenticate Users with Identity-Aware Proxy"
        )
        ;;

    3)
        lst=(
            "Multiple VPC"
            "Control Access to VPC Networks Using Firewall Rules and IAM"
            "Configure an Application Load Balancer with Google Cloud Armor"
            "Monitor a Compute Engine Instance with Cloud Monitoring"
        )
        ;;

    4)
        lst=(
            "Manage Apache Spark Clusters Using the gcloud CLI"
            "Build a Streaming Pipeline Using Dataflow Templates"
            "Build and Run a Dataflow Pipeline Using Python"
            "Cloud Natural Language API: Qwik Start (all-in-one script)"
            "Annotate Videos Using the Video Intelligence API"
            "Speech-to-Text API"
        )
        ;;
esac

# Display Available Files
count=1

for file in "${lst[@]}"; do
    echo "$count: \"$file\""
    ((count++))
done

echo

# Choose File
read -p "Enter the Input number for Choose the file name: " choose_file_input

# Validate File Number
if ! [[ "$choose_file_input" =~ ^[0-9]+$ ]] || \
   (( choose_file_input < 1 || choose_file_input >= count )); then
    echo "Wrong Input, Enter the Number"
    exit 1
fi

# Generate Python Command
selected_file="${lst[$((choose_file_input-1))]}"

echo
bash "~/GCCF-Ingage-Technologies-Course-Completion/${choose_folder_name[$((choose_the_course_no-1))]}/$selected_file.sh"
