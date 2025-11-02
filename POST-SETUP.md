# ======================================================================
# 🚀 POST-SETUP GUIDE — Weaversoft Platform
# ======================================================================
# This guide explains exactly what to do after editing configuration files
# (values.yaml, Chart.yaml, Dockerfile) before deploying your application
# to the Kubernetes cluster.
# ======================================================================

# 🧩 STEP 1: VERIFY CONFIGURATION
# Make sure these fields are updated in chart/values.yaml:
#   image.repository  → Full registry path (e.g., registry.weaversoft.io/backend/my-service)
#   image.tag         → Version or commit SHA (e.g., v1.0.0 or abc1234)
#   labels.owner      → Team or owner name
#   service.port      → App listening port (e.g., 3000, 8080)
# Optional:
#   labels.dcsIngress.host → Domain (leave empty for auto)
# Recommended:
#   resources → CPU/memory requests and limits for production
#
# Then check chart/Chart.yaml:
#   name       → Application name (set by bootstrap.sh)
#   version    → Chart version (bump if chart changes)
#   appVersion → Match your image tag

# ======================================================================
# 🐋 STEP 2: BUILD & PUSH DOCKER IMAGE (ALWAYS FIRST)
# ======================================================================
# Build the Docker image and push it to the registry BEFORE packaging Helm.
# This ensures the image exists when Kubernetes tries to pull it.
#
# Replace <team>, <app>, <tag> with your actual values.

docker build -t registry.weaversoft.io/<team>/<app>:<tag> -f docker/Dockerfile.base .
docker push registry.weaversoft.io/<team>/<app>:<tag>

# ✅ If this step is skipped, your Pods will fail with ImagePullBackOff.

# ======================================================================
# 📦 STEP 3: VALIDATE AND PACKAGE THE HELM CHART
# ======================================================================
# Once the image is in the registry, validate and package your chart.

helm lint chart
helm template my-app chart --validate

# If validation passes, package the Helm chart:
helm package chart --destination dist

# Expected output:
# dist/my-app-0.1.0.tgz

# ======================================================================
# ☸️ STEP 4: DEPLOY TO KUBERNETES
# ======================================================================
# Install or upgrade your app using Helm.
# Replace <namespace> with the appropriate one.

# First-time installation:
helm install my-app dist/my-app-0.1.0.tgz --namespace <namespace> --create-namespace

# For updating an existing app:
helm upgrade my-app dist/my-app-0.1.0.tgz --namespace <namespace>

# ✅ Kyverno will automatically detect `expose: "true"` on the Service
# and create an HTTPRoute for NGINX Gateway Fabric with TLS.

# ======================================================================
# 🔍 STEP 5: VERIFY DEPLOYMENT
# ======================================================================
# Confirm that all components were created successfully.

kubectl get pods -n <namespace>
kubectl get svc -n <namespace>
kubectl get httproute -n <namespace>

# Example expected output:
# NAME                           READY   STATUS    RESTARTS   AGE
# my-service-7d8f9fcd67-wl8g4    1/1     Running   0          2m
#
# NAME           TYPE        CLUSTER-IP       PORT(S)   AGE
# my-service     ClusterIP   10.104.112.21    80/TCP    2m
#
# NAME           HOSTNAME                      PATH   STATUS
# my-service     my-service.backend.prod.io     /      Accepted

# ======================================================================
# 🧩 STEP 6: OPTIONAL — CLEANUP OR REDEPLOY
# ======================================================================
# To uninstall the application completely:
helm uninstall my-app -n <namespace>

# To redeploy a new version:
#   1. Update image.tag and appVersion in chart files
#   2. Rebuild and push the Docker image
#   3. Repackage Helm chart
#   4. Run helm upgrade
helm upgrade my-app dist/my-app-0.1.0.tgz --namespace <namespace>

# ======================================================================
# 📄 STEP 7: FINAL OUTPUT SUMMARY
# ======================================================================
# After completing all steps successfully, you will have:

# 🐋 Docker Image:
#   registry.weaversoft.io/backend/my-service:v1.0.0

# 📦 Helm Package (.tgz):
#   dist/my-service-0.1.0.tgz

# ☸️ Running Application:
#   Accessible at https://my-service.backend.prod.io
#
# Verify by checking HTTPRoute status = Accepted and Pod status = Running.

# ======================================================================
# ⚠️ COMMON MISTAKES TO AVOID
# ======================================================================
# 1. Creating Helm .tgz before pushing Docker image → Pods fail.
# 2. Forgetting to bump version in Chart.yaml → Helm reuses cache.
# 3. Leaving empty fields in values.yaml → Helm validation errors.
# 4. Overwriting labels → Kyverno won’t generate HTTPRoute.
# 5. Using root user in image → Blocked by cluster security policies.

# ======================================================================
# ✅ QUICK SUMMARY WORKFLOW
# ======================================================================
# 1️⃣ Edit all configs (values.yaml, Chart.yaml, Dockerfile)
# 2️⃣ Build and push Docker image
# 3️⃣ Validate Helm chart (helm lint / template)
# 4️⃣ Package Helm chart (helm package chart --destination dist)
# 5️⃣ Deploy to cluster (helm install or upgrade)
# 6️⃣ Verify (pods, services, httproute)
# ======================================================================

echo "🎉 Deployment complete! Application is now live on the Weaversoft Platform."
