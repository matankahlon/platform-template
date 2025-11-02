# DCS Platform Template

A standard template for Kubernetes applications using Helm. This template provides a Helm package (Deployment/Service/ConfigMap) that is composed uniformly.

**What's special here?**
- HTTPRoute is created automatically by Kyverno for NGINX Gateway Fabric (no need to create manually!)
- Automatic TLS support using cluster-wide certificate
- Built-in security settings (non-root, read-only filesystem)
- Unified template for all company applications

---

## 🚀 Quick Start

### Step 1: Create a new application
```bash
# Option A: Create application from GitHub Template
# Click "Use this template" on GitHub, or:

# Option B: Clone and customize
git clone <this-repo> my-new-app
cd my-new-app

# Update Chart name (your application)
# This updates Chart.yaml only - helper functions in templates remain unchanged
./scripts/bootstrap.sh my-awesome-app
```

### Step 2: Configure the application
```bash
# Edit the main configuration file
vim chart/values.yaml

# 🔧 What must be changed:
# 1. image.repository - Your registry address (e.g., "registry.company.com/my-team/my-app")
# 2. image.tag - Image tag (recommended: git-sha or semver, not "latest")
# 3. service.port - Port that the application listens on (e.g., 3000, 8080)
# 4. labels.owner - Team/owner name (e.g., "backend-team")
# 5. labels.dcsIngress.host - Domain if desired (or leave empty for auto)
# 6. labels.dcsIngress.path - URL path (e.g., "/api/v1")
```

### Step 3: Validate and verify
```bash
# Check everything is correct (validation)
helm lint chart

# Preview templates that will be generated (preview)
helm template my-awesome-app chart | less

# Validate against Schema (validation of values)
helm template my-awesome-app chart --validate
```

### Step 4: Package and distribute (optional)
```bash
# Package the Chart for deployment
helm package chart --destination dist

# Result: dist/my-awesome-app-0.1.0.tgz
```

---

## 📁 What's included in the template?

```
platform-template/
├── chart/                    # Helm Chart - Main file
│   ├── Chart.yaml           # Chart metadata (name, version, description)
│   ├── values.yaml          # 🔧 Configuration file - configure your application here!
│   ├── values.schema.json   # Schema for validation (no need to change)
│   └── templates/           # Kubernetes templates
│       ├── _helpers.tpl     # Helper functions (no need to change)
│       ├── deployment.yaml  # Deployment - runs the Pods
│       ├── service.yaml     # Service - internal access point to Pods
│       └── configmap.yaml   # ConfigMap - configuration files (if needed)
├── docker/
│   └── Dockerfile.base     # Docker template (optional - if needed)
├── ci/
│   └── build-and-publish.yaml  # GitHub Actions - CI/CD pipeline
├── scripts/
│   └── bootstrap.sh        # Script to update Chart name
├── platform-config.yaml    # General platform settings (optional)
└── README.md               # This file
```

---

## 🔧 What needs to be changed? (Developer Checklist)

### ✅ Must change (`chart/values.yaml`):
- [ ] `image.repository` - Registry address of the image
- [ ] `image.tag` - Image tag (recommended: git-sha or semver)
- [ ] `service.port` - Port that the application listens on
- [ ] `labels.owner` - Team/owner name
- [ ] `replicaCount` - Number of Pods (at least 2 for production)

### 🔧 Recommended to change (`chart/values.yaml`):
- [ ] `labels.dcsIngress.host` - Domain (if desired, otherwise Kyverno will set automatically)
- [ ] `labels.dcsIngress.path` - URL path (e.g., "/api/v1")
- [ ] `resources` - CPU/memory limits (must for production!)
- [ ] `env` - Environment variables (if application needs)
- [ ] `livenessProbe` / `readinessProbe` - Health checks (critical for production!)

### 🔧 Optional (`chart/values.yaml`):
- [ ] `config.enabled` + `config.data` - If need config files
- [ ] `image.pullSecrets` - If private registry
- [ ] `podAnnotations` / `podLabels` - If need special annotations/labels
- [ ] `nodeSelector` / `affinity` / `tolerations` - If need Pods on specific nodes
- [ ] `initContainers` - If need to run setup before main container (migrations, waiting for dependencies)
- [ ] `startupProbe` - For slow-starting applications (>30s to start)
- [ ] `lifecycle` - Pre-stop/post-start hooks for graceful shutdown
- [ ] `extraVolumes` / `extraVolumeMounts` - For additional storage needs
- [ ] `serviceAccount.name` - Use existing ServiceAccount if needed for RBAC

### ✅ Change only if needed:
- `chart/Chart.yaml` - Chart name, version, description

### ❌ Don't change (unless there's a good reason):
- `chart/templates/*.yaml` - Kubernetes templates (unless special change needed)
- `chart/values.schema.json` - Schema validation
- `chart/templates/_helpers.tpl` - Helper functions

---

## 🔍 How does it work? (Architecture)

### 1. Helm Chart
- **Chart.yaml**: Metadata (name, version, description)
- **values.yaml**: Application configuration (what developer changes)
- **templates/**: Kubernetes templates that create Deployment/Service/ConfigMap

### 2. Kubernetes Resources
- **Deployment**: Runs the Pods, ensures enough Pods, performs rolling updates
- **Service**: Internal access point to Pods (internal DNS, load balancing)
- **ConfigMap**: Configuration files (if `config.enabled = true`)

### 3. Kyverno + NGINX Gateway Fabric Integration (Automatic HTTPRoute creation)
**⚠️ Important**: HTTPRoute is created automatically by Kyverno, not manually!

**📝 Note**: HTTPRoute (part of Gateway API) is the modern replacement for the legacy Ingress resource. It provides better functionality, standardization, and is what NGINX Gateway Fabric uses.

- Service gets annotation `expose: "true"` (if `ingress.enabled = true`)
- Kyverno reads the annotation and labels
- Kyverno creates HTTPRoute automatically for NGINX Gateway Fabric (not Ingress!)
- NGINX Gateway Fabric routes traffic using the HTTPRoute
- TLS is handled automatically using cluster-wide certificate (if `labels.dcsIngress.tls = true`)
- Labels used by Kyverno (note: we use "ingress" in label names for convention, but they create HTTPRoute resources):
  - `dcs.ingress/enabled`: Whether to create HTTPRoute
  - `dcs.ingress/host`: Domain (if empty, Kyverno will set automatically)
  - `dcs.ingress/path`: URL path
  - `dcs.ingress/tls`: Enable TLS (uses cluster-wide certificate)

### 4. Standard Labels
Every Resource gets labels:
- `managed-by: dcs-platform` - Identifies that the app is managed by the platform
- `owner: <team-name>` - Application owner (change in values.yaml)
- `dcs.ingress/*` - HTTPRoute metadata (for Kyverno to create HTTPRoute resources)

---

## 📚 Usage Examples

### Example 1: Simple application (Node.js)
```yaml
# chart/values.yaml
image:
  repository: "registry.company.com/frontend-team/my-app"
  tag: "v1.2.3"

service:
  port: 3000

labels:
  owner: "frontend-team"
  dcsIngress:
    host: "my-app.example.com"
    path: "/"

env:
  - name: NODE_ENV
    value: "production"
  - name: PORT
    value: "3000"
```

### Example 2: Application with config files
```yaml
# chart/values.yaml
image:
  repository: "registry.company.com/backend-team/api"
  tag: "abc1234"

service:
  port: 8080

config:
  enabled: true
  data:
    app.properties: |
      database.url=jdbc:postgresql://db:5432/mydb
      logging.level=INFO
    config.yaml: |
      server:
        port: 8080
        timeout: 30s
```

### Example 3: Application with resources and advanced settings
```yaml
# chart/values.yaml
image:
  repository: "registry.company.com/data-team/processor"
  tag: "v2.1.0"

replicaCount: 3  # High availability

service:
  port: 5000

resources:
  limits:
    cpu: "1000m"
    memory: "1Gi"
  requests:
    cpu: "500m"
    memory: "512Mi"

env:
  - name: WORKER_THREADS
    value: "4"
  - name: QUEUE_SIZE
    value: "1000"
```

---

## 🔄 CI/CD

The template includes a GitHub Actions example (`ci/build-and-publish.yaml`):

```yaml
# The example includes:
# 1. Build Docker image
# 2. Push to Registry
# 3. Package Helm Chart
# 4. Upload artifacts
```

**Required settings in GitHub Secrets:**
- `DCS_REGISTRY_URL` - Registry address
- `DCS_REGISTRY_USER` - Username
- `DCS_REGISTRY_PASSWORD` - Password

**Customization:**
- Update image paths in `ci/build-and-publish.yaml`
- Adjust tags (git-sha, semver, etc.)

---

## 🛠️ Useful Commands

```bash
# Validate
helm lint chart

# Preview templates
helm template my-app chart

# Validate against Schema
helm template my-app chart --validate

# Package Chart
helm package chart --destination dist

# Local installation (example/testing)
helm install my-app chart --dry-run --debug

# Update Chart name
./scripts/bootstrap.sh my-new-app-name
```

---

## ⚠️ Important Notes

1. **Automatic HTTPRoute**: No need to create HTTPRoute manually - Kyverno does it automatically! (HTTPRoute is the modern replacement for Ingress, part of Gateway API)
2. **Security**: The template includes built-in security settings (non-root, read-only filesystem). If the application needs something else, update in `values.yaml`.
3. **Resources**: Important to set `resources` (CPU/memory) for production!
4. **Registry**: Working in air-gapped environment is possible if images are available in internal registry.

---

## 📖 More Information

- **Helm**: https://helm.sh/docs/
- **Kubernetes**: https://kubernetes.io/docs/
- **Kyverno**: https://kyverno.io/docs/
- **Gateway API**: https://gateway-api.sigs.k8s.io/

---

## 💡 Frequently Asked Questions (FAQ)

**Q: Where do I change the port that the application listens on?**  
A: `chart/values.yaml` → `service.port`

**Q: How do I add environment variables?**  
A: `chart/values.yaml` → `env: [ { name: "KEY", value: "VAL" } ]`

**Q: How do I mount config files?**  
A: `chart/values.yaml` → `config.enabled: true` + `config.data: { "file.txt": "content" }`

**Q: How do I change the domain/URL?**  
A: `chart/values.yaml` → `labels.dcsIngress.host` + `labels.dcsIngress.path`

**Q: Why is HTTPRoute not created?**  
A: Make sure `ingress.enabled: true` in `values.yaml` (gives Service the `expose: "true"` annotation)

**Q: How does TLS work?**  
A: TLS is enabled by default (`labels.dcsIngress.tls: true`). It uses the cluster-wide certificate managed by NGINX Gateway Fabric. No certificate configuration needed!

**Q: Can I disable TLS for a specific app?**  
A: Yes, set `labels.dcsIngress.tls: false` in `values.yaml`

**Q: How does Kyverno create the HTTPRoute?**  
A: Kyverno watches Services with `expose: "true"` annotation and reads the `dcs.ingress/*` labels to automatically create HTTPRoute resources for NGINX Gateway Fabric.

**Q: How do I add health checks?**  
A: `chart/values.yaml` → `livenessProbe` and `readinessProbe`. See examples in values.yaml comments.

**Q: How do I run database migrations before the app starts?**  
A: `chart/values.yaml` → `initContainers: [ { name: "migrate", image: "...", command: [...] } ]`

**Q: How do I use an existing ServiceAccount for RBAC?**  
A: `chart/values.yaml` → `serviceAccount.name: "existing-sa-name"`

**Q: How do I add persistent storage or other advanced features?**  
A: You can add template files (like `pvc.yaml`, `pdb.yaml`, `serviceaccount.yaml`) as needed. The deployment template supports these features through `extraVolumes` and configuration.

---

**Need help?** Contact the platform team or check the comments in the template files! 🚀
