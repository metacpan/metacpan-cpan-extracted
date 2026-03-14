#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

KUBECONFIG_PATH="${KUBECONFIG_PATH:-/storage/raid/home/getty/avatar/.kube/config}"
NAMESPACE="${NAMESPACE:-zitadel}"
DB_RELEASE="${DB_RELEASE:-db}"
ZITADEL_RELEASE="${ZITADEL_RELEASE:-my-zitadel}"
DOMAIN="${DOMAIN:-zitadel.avatar.conflict.industries}"
GATEWAY_NAME="${GATEWAY_NAME:-cilium-gateway}"
GATEWAY_NAMESPACE="${GATEWAY_NAMESPACE:-kube-system}"
ZITADEL_IMAGE_REPOSITORY="${ZITADEL_IMAGE_REPOSITORY:-ghcr.io/zitadel/zitadel}"
ZITADEL_IMAGE_TAG="${ZITADEL_IMAGE_TAG:-v4.12.2}"

export HELM_CACHE_HOME="${HELM_CACHE_HOME:-/tmp/helm-cache}"
export HELM_CONFIG_HOME="${HELM_CONFIG_HOME:-/tmp/helm-config}"
export HELM_DATA_HOME="${HELM_DATA_HOME:-/tmp/helm-data}"
mkdir -p "$HELM_CACHE_HOME" "$HELM_CONFIG_HOME" "$HELM_DATA_HOME"

kubecfg() {
  KUBECONFIG="$KUBECONFIG_PATH" kubectl "$@"
}

helm repo add zitadel https://charts.zitadel.com >/dev/null
helm repo update >/dev/null

kubecfg get ns "$NAMESPACE" >/dev/null 2>&1 || kubecfg create ns "$NAMESPACE"

kubecfg apply -f "$ROOT_DIR/k8s/zitadel/gateway-cert.yaml"
kubecfg wait -n kube-system --for=condition=Ready certificate/default-gateway-cert --timeout=180s

# Clean up an old bitnami db release if present, then deploy the simple postgres stack.
helm --kubeconfig "$KUBECONFIG_PATH" -n "$NAMESPACE" uninstall "$DB_RELEASE" >/dev/null 2>&1 || true
kubecfg apply -f "$ROOT_DIR/k8s/zitadel/postgres.yaml"
kubecfg -n "$NAMESPACE" rollout status deploy/zitadel-postgres --timeout=300s

TMP_VALUES="$(mktemp)"
trap 'rm -f "$TMP_VALUES"' EXIT
sed \
  -e "s/zitadel\.avatar\.conflict\.industries/${DOMAIN}/g" \
  -e "s/my-zitadel/${ZITADEL_RELEASE}/g" \
  -e "s|__ZITADEL_IMAGE_REPOSITORY__|${ZITADEL_IMAGE_REPOSITORY}|g" \
  -e "s|__ZITADEL_IMAGE_TAG__|${ZITADEL_IMAGE_TAG}|g" \
  "$ROOT_DIR/k8s/zitadel/zitadel-values.yaml" > "$TMP_VALUES"

helm upgrade --install "$ZITADEL_RELEASE" zitadel/zitadel \
  --kubeconfig "$KUBECONFIG_PATH" \
  --namespace "$NAMESPACE" \
  --wait \
  -f "$TMP_VALUES"

TMP_ROUTE="$(mktemp)"
trap 'rm -f "$TMP_VALUES" "$TMP_ROUTE"' EXIT
sed \
  -e "s/my-zitadel/${ZITADEL_RELEASE}/g" \
  -e "s/zitadel\.avatar\.conflict\.industries/${DOMAIN}/g" \
  -e "s/name: cilium-gateway/name: ${GATEWAY_NAME}/g" \
  -e "s/namespace: kube-system/namespace: ${GATEWAY_NAMESPACE}/g" \
  "$ROOT_DIR/k8s/zitadel/httproute.yaml" > "$TMP_ROUTE"
kubecfg apply -f "$TMP_ROUTE"

kubecfg -n "$NAMESPACE" rollout status deploy/"$ZITADEL_RELEASE"-zitadel --timeout=300s

cat <<MSG
ZITADEL deployed.
Issuer: https://${DOMAIN}
Console: https://${DOMAIN}/ui/console

Run live tests:
  ZITADEL_LIVE_TEST=1 \\
  ZITADEL_K8S_TEST=1 \\
  ZITADEL_ISSUER=https://${DOMAIN} \\
  ZITADEL_KUBECONFIG=${KUBECONFIG_PATH} \\
  prove -lv t/90-live-zitadel.t t/91-k8s-pod.t

Image used:
  ${ZITADEL_IMAGE_REPOSITORY}:${ZITADEL_IMAGE_TAG}
MSG
