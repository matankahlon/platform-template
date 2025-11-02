#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <app-name>" >&2
  exit 1
fi

APP_NAME="$1"

# Update chart name and helpers
sed -i "s/^name: .*/name: ${APP_NAME}/" "$(dirname "$0")/../chart/Chart.yaml"

# Update helpers fullname prefix release-name becomes <release>-<app>
sed -i "s/dcs-app/${APP_NAME}/g" "$(dirname "$0")/../chart/templates/_helpers.tpl"

echo "Bootstrap complete. Set image repo/tag and owner in chart/values.yaml"

