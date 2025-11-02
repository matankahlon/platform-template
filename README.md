# DCS Platform Template

A reusable template repo for DCS applications. It provides a standardized Helm chart (Deployment/Service/ConfigMap only). Ingress/HTTPRoute is created automatically by Kyverno from Service annotation `expose: "true"` and labels. No Ingress manifests here.

## Quick start (as a new app)

```bash
# 1) Use this repo as a template (GitHub: Use this template / or git clone)
# 2) Rename app/chart quickly
./scripts/bootstrap.sh my-awesome-app  # sets chart/app name

# 3) Edit values
vim chart/values.yaml   # set image.repository, tag, service.port, labels.owner, etc.

# 4) Render and verify
helm lint chart
helm template my-awesome-app chart | less

# 5) Package (optional)
helm package chart --destination dist
```

## What you get
- chart/Chart.yaml
- chart/templates: Deployment, Service, ConfigMap
- chart/values.yaml + values.schema.json (validation)
- docker/Dockerfile.base (OCI labels, non-root)
- ci/build-and-publish.yaml (example GitHub Actions)
- platform-config.yaml (platform-wide conventions, optional)

## Kyverno integration (cluster expectation)
- HTTPRoute is generated when Service has annotation `expose: "true"`.
- Standard labels are attached to resources:
  - `managed-by: dcs-platform`
  - `owner: default` (change per team)
  - `dcs.ingress/enabled`, `dcs.ingress/host`, `dcs.ingress/path`

This chart only provides metadata for ingress; it does not create Ingress/HTTPRoute.

## Customize per app
- `chart/values.yaml`
  - `image.repository`, `image.tag`
  - `service.port` (default 80)
  - `labels.owner`
  - `ingress.enabled` (true => Service gets `expose: "true"`)
  - `labels.dcsIngress.host` and `labels.dcsIngress.path` (metadata only)
- `platform-config.yaml` is optional guidance for platform defaults.

## CI/CD
- `ci/build-and-publish.yaml` uses registry credentials from secrets:
  - `DCS_REGISTRY_URL`, `DCS_REGISTRY_USER`, `DCS_REGISTRY_PASSWORD`
- Adjust tags and image path as needed.

## Notes
- No Ingress manifests are included. Kyverno + Gateway API handle exposure.
- Works in air-gapped environments when your images are available in the internal registry.
