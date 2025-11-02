#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh - Script to Update Chart Name
# This file updates the Chart name in Chart.yaml
# ==============================================================================
# Usage: ./scripts/bootstrap.sh <app-name>
# Example: ./scripts/bootstrap.sh my-awesome-app
# 
# Note: Helper function names in _helpers.tpl (dcs-app.name, dcs-app.fullname)
#       remain unchanged as they are template conventions used by all templates.
# ==============================================================================

# Bash strict mode - stops if there's an error or undefined variable
set -euo pipefail

# Check that there's one parameter (application name)
if [ $# -ne 1 ]; then
  echo "Usage: $0 <app-name>" >&2
  echo "Example: $0 my-awesome-app" >&2
  exit 1
fi

APP_NAME="$1"

# Update Chart name in Chart.yaml
# Finds line starting with "name: " and replaces entire line with "name: <app-name>"
sed -i "s/^name: .*/name: ${APP_NAME}/" "$(dirname "$0")/../chart/Chart.yaml"

# Note: We do NOT replace "dcs-app" in _helpers.tpl because:
# - "dcs-app.name" and "dcs-app.fullname" are helper function names (template conventions)
# - All templates reference these helpers using {{ include "dcs-app.name" . }}
# - Changing helper names would break all template references
# - The helper functions automatically use .Chart.Name which is set in Chart.yaml above

# Success message
echo "✅ Bootstrap complete!"
echo "📝 Next steps:"
echo "   1. Set image.repository in chart/values.yaml"
echo "   2. Set image.tag in chart/values.yaml"
echo "   3. Set labels.owner in chart/values.yaml"
echo "   4. Set service.port in chart/values.yaml (if different from 80)"
