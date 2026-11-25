#!/usr/bin/env bash
# =============================================================================
# GSP080 - Deploy a Cloud Run Function via the Command Line   via the Command Line (all-in-one script)
# Run this in Google Cloud Shell:  bash deploy_cloud_run_function.sh
#
# NOTE: Student lab accounts cannot enable APIs (the lab has them enabled
#       already), so this script does NOT try to enable any service.
#       It also does not stop on non-critical errors; only npm install and
#       the deployment itself are treated as critical.
#       Fix for 403 serviceusage.services.use: role grant + deploy retry loop.
# =============================================================================
set -uo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 0. INPUT VARIABLES (press ENTER to accept the [default] shown in brackets)
# -----------------------------------------------------------------------------
gcloud auth login --no-launch-browser
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=${ZONE%-*}

gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE


#DEFAULT_REGION="us-central1"          # LOCATION / REGION used by the lab
#DEFAULT_ZONE="${DEFAULT_REGION}-c" # Lab does not use a zone; kept as a variable for completeness

#read -rp "Enter PROJECT_ID [${DEFAULT_PROJECT_ID}]: " PROJECT_ID
#PROJECT_ID="${PROJECT_ID:-$DEFAULT_PROJECT_ID}"

#read -rp "Enter REGION / LOCATION [${DEFAULT_REGION}]: " REGION
#REGION="${REGION:-$DEFAULT_REGION}"

#read -rp "Enter ZONE [${DEFAULT_ZONE}]: " ZONE
#ZONE="${ZONE:-$DEFAULT_ZONE}"

[[ -z "${PROJECT_ID}" ]] && die "PROJECT_ID cannot be empty."

# Values taken from the lab, now driven by the variables above
FUNCTION_NAME="nodejs-pubsub-function"
ENTRY_POINT="helloPubSub"
TOPIC_NAME="cf-demo"
RUNTIME="nodejs22"
SOURCE_DIR="gcf_hello_world"
STAGE_BUCKET="${PROJECT_ID}-bucket"
SERVICE_ACCOUNT="cloudfunctionsa@${PROJECT_ID}.iam.gserviceaccount.com"
TEST_MESSAGE="Cloud Function Gen2"

echo
echo "================ Configuration ================"
echo "PROJECT_ID      : ${PROJECT_ID}"
echo "REGION          : ${REGION}"
echo "ZONE            : ${ZONE}"
echo "FUNCTION_NAME   : ${FUNCTION_NAME}"
echo "TOPIC_NAME      : ${TOPIC_NAME}"
echo "STAGE_BUCKET    : ${STAGE_BUCKET}"
echo "SERVICE_ACCOUNT : ${SERVICE_ACCOUNT}"
echo
echo
echo
echo
echo "If Choice asked 'Y'/'N' --> Press 'N' [either Capital or Small Letter]"
echo
echo "If any error occur Don't Cancel or Quit it"
echo
echo
echo "==============================================="
echo

# -----------------------------------------------------------------------------
# 1. GCLOUD DEFAULTS
# -----------------------------------------------------------------------------
echo ">>> Setting gcloud defaults..."
gcloud config set project "${PROJECT_ID}"
gcloud config set run/region "${REGION}"
gcloud config set compute/region "${REGION}"
gcloud config set compute/zone "${ZONE}"

echo ">>> Active account and project:"
gcloud auth list
gcloud config list project

# -----------------------------------------------------------------------------
# TASK 1. CREATE THE FUNCTION
# -----------------------------------------------------------------------------
echo ">>> Task 1: Creating function source code..."
mkdir -p "${SOURCE_DIR}" || die "Could not create directory ${SOURCE_DIR}"
cd "${SOURCE_DIR}" || die "Could not enter directory ${SOURCE_DIR}"

cat > index.js <<'EOF'
const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback with the Functions Framework that will
// be executed when the Pub/Sub trigger topic receives a message.
functions.cloudEvent('helloPubSub', cloudEvent => {
  // The Pub/Sub message is passed as the CloudEvent's data payload.
  const base64name = cloudEvent.data.message.data;

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World';

  console.log(`Hello, ${name}!`);
});
EOF

cat > package.json <<'EOF'
{
  "name": "gcf_hello_world",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF

echo ">>> Installing npm dependencies..."
npm install || die "npm install failed"

# -----------------------------------------------------------------------------
# TASK 2. DEPLOY THE FUNCTION
# -----------------------------------------------------------------------------
echo ">>> Task 2: Checking prerequisites (non-fatal)..."

# Pub/Sub topic: create only if missing (the deploy also creates it if needed)
if gcloud pubsub topics describe "${TOPIC_NAME}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Topic '${TOPIC_NAME}' already exists."
else
  gcloud pubsub topics create "${TOPIC_NAME}" --project="${PROJECT_ID}" \
    || echo "WARNING: Could not create topic now; the deployment will create it."
fi

# Staging bucket: the lab provides it; warn only
if gcloud storage buckets describe "gs://${STAGE_BUCKET}" >/dev/null 2>&1; then
  echo "Bucket 'gs://${STAGE_BUCKET}' found."
else
  echo "WARNING: Bucket gs://${STAGE_BUCKET} not visible. Trying to create it..."
  gcloud storage buckets create "gs://${STAGE_BUCKET}" \
    --project="${PROJECT_ID}" --location="${REGION}" \
    || echo "WARNING: Could not create bucket; continuing."
fi

# Service account: use it only if it exists in this project
SA_ARGS=()
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  SA_ARGS=(--service-account "${SERVICE_ACCOUNT}")
else
  echo "WARNING: ${SERVICE_ACCOUNT} not found. Deploying with the default service account."
fi

# -----------------------------------------------------------------------------
# PERMISSION FIX for: 403 "Caller does not have required permission to use project"
# Eventarc validates the trigger using serviceusage.services.use, which is part of
# roles/serviceusage.serviceUsageConsumer. We grant it (best effort), then retry the
# deployment while IAM propagates (this can take a few minutes on a fresh lab).
# -----------------------------------------------------------------------------
ACTIVE_ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
MEMBERS=("user:${ACTIVE_ACCOUNT}")
[[ ${#SA_ARGS[@]} -gt 0 ]] && MEMBERS+=("serviceAccount:${SERVICE_ACCOUNT}")

echo
echo ">>> Granting roles/serviceusage.serviceUsageConsumer (best effort)..."
for MEMBER in "${MEMBERS[@]}"; do
  if gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
      --member="${MEMBER}" \
      --role="roles/serviceusage.serviceUsageConsumer" \
      --condition=None --quiet >/dev/null 2>&1; then
    echo "Granted to ${MEMBER}"
  else
    echo "NOTE: Could not grant to ${MEMBER} (lab may already provide it). Continuing."
  fi
done

echo
echo ">>> Deploying ${FUNCTION_NAME} (this takes a few minutes)..."
echo ">>> If asked about 'serviceAccountTokenCreator', type  n  and press ENTER (as the lab advises)."
echo

MAX_DEPLOY_ATTEMPTS=5
DEPLOY_WAIT_SECONDS=60
DEPLOY_RC=1

for ((d = 1; d <= MAX_DEPLOY_ATTEMPTS; d++)); do
  echo ">>> Deployment attempt ${d}/${MAX_DEPLOY_ATTEMPTS}..."
  gcloud functions deploy "${FUNCTION_NAME}" \
    --gen2 \
    --runtime="${RUNTIME}" \
    --region="${REGION}" \
    --source=. \
    --entry-point="${ENTRY_POINT}" \
    --trigger-topic "${TOPIC_NAME}" \
    --stage-bucket "${STAGE_BUCKET}" \
    "${SA_ARGS[@]}" \
    --allow-unauthenticated \
    --project="${PROJECT_ID}"
  DEPLOY_RC=$?

  [[ ${DEPLOY_RC} -eq 0 ]] && break

  if (( d < MAX_DEPLOY_ATTEMPTS )); then
    echo
    echo "Deployment failed. Waiting ${DEPLOY_WAIT_SECONDS}s for IAM permission propagation, then retrying..."
    sleep "${DEPLOY_WAIT_SECONDS}"
  fi
done

[[ ${DEPLOY_RC} -ne 0 ]] && die "Function deployment failed after ${MAX_DEPLOY_ATTEMPTS} attempts. Review the messages above."

echo
echo ">>> Verifying function status..."
gcloud functions describe "${FUNCTION_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}"

STATE="$(gcloud functions describe "${FUNCTION_NAME}" \
  --region="${REGION}" --project="${PROJECT_ID}" \
  --format='value(state)' 2>/dev/null)"
echo "Function state: ${STATE}"
[[ "${STATE}" != "ACTIVE" ]] && die "Function is not ACTIVE yet. Re-run the describe command after a minute."

echo
echo ">>> DEPLOYMENT DONE. You can click 'Check my progress' for Task 2 now."
echo

# -----------------------------------------------------------------------------
# TASK 3. TEST THE FUNCTION
# -----------------------------------------------------------------------------
echo ">>> Task 3: Publishing a test message to Pub/Sub topic '${TOPIC_NAME}'..."
gcloud pubsub topics publish "${TOPIC_NAME}" \
  --message="${TEST_MESSAGE}" \
  --project="${PROJECT_ID}"

# -----------------------------------------------------------------------------
# TASK 4. VIEW LOGS (logs may take a few minutes; retry up to ~10 minutes)
# -----------------------------------------------------------------------------
echo ">>> Task 4: Reading logs (will retry until the message appears)..."
MAX_ATTEMPTS=20
SLEEP_SECONDS=30
FOUND=false

for ((i = 1; i <= MAX_ATTEMPTS; i++)); do
  LOGS="$(gcloud functions logs read "${FUNCTION_NAME}" \
    --region="${REGION}" --project="${PROJECT_ID}" 2>/dev/null || true)"

  if grep -q "Hello, ${TEST_MESSAGE}!" <<<"${LOGS}"; then
    echo "${LOGS}"
    FOUND=true
    break
  fi

  echo "Attempt ${i}/${MAX_ATTEMPTS}: log entry not visible yet. Retrying in ${SLEEP_SECONDS}s..."
  sleep "${SLEEP_SECONDS}"
done

echo
if [[ "${FOUND}" == true ]]; then
  echo "SUCCESS: Function deployed, tested, and logs verified (Hello, ${TEST_MESSAGE}!)."
else
  echo "Logs not visible yet. Re-run this command after a few minutes:"
  echo "  gcloud functions logs read ${FUNCTION_NAME} --region=${REGION} --project=${PROJECT_ID}"
  echo "Or open: Logging > Logs Explorer in the Cloud console."
fi
