#!/usr/bin/env bash
set -euo pipefail

FIGMA_MCP_URL="https://mcp.figma.com/mcp"
CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME_DIR/config.toml"

usage() {
  cat <<'USAGE'
Usage:
  scripts/figma_mcp_auth.sh
  scripts/figma_mcp_auth.sh --repair-config
  scripts/figma_mcp_auth.sh --login
  scripts/figma_mcp_auth.sh --repair-and-login
  scripts/figma_mcp_auth.sh --open-token-page

What it does:
  - Default mode prints local Figma MCP auth diagnostics.
  - --repair-config backs up ~/.codex/config.toml and recreates the figma MCP entry with oauth_resource.
  - --login runs `codex mcp login figma`, which should open the Figma OAuth page.
  - --repair-and-login repairs the config first, then starts OAuth login.
  - --open-token-page opens Figma's token documentation as a fallback for bearer-token setup.
USAGE
}

section() {
  printf '\n== %s ==\n' "$1"
}

figma_section() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return 0
  fi

  awk '
    /^\[mcp_servers\.figma\]/ { inside = 1; next }
    /^\[/ { inside = 0 }
    inside { print }
  ' "$CONFIG_FILE"
}

print_status() {
  section "Codex"
  if command -v "$CODEX_BIN" >/dev/null 2>&1; then
    command -v "$CODEX_BIN"
  else
    echo "codex CLI not found on PATH"
  fi

  section "Config"
  echo "CODEX_HOME=$CODEX_HOME_DIR"
  echo "config=$CONFIG_FILE"
  if [[ -f "$CONFIG_FILE" ]]; then
    echo "config exists"
  else
    echo "config missing"
  fi

  section "Figma MCP config"
  local config
  config="$(figma_section || true)"
  if [[ -z "$config" ]]; then
    echo "No [mcp_servers.figma] section found."
  else
    printf '%s\n' "$config"
  fi

  if printf '%s\n' "$config" | grep -q 'oauth_resource'; then
    echo "oauth_resource: present"
  else
    echo "oauth_resource: missing"
  fi

  if printf '%s\n' "$config" | grep -q 'bearer_token_env_var'; then
    echo "bearer_token_env_var: present"
  else
    echo "bearer_token_env_var: missing"
  fi

  section "Environment"
  if [[ -n "${FIGMA_OAUTH_TOKEN:-}" ]]; then
    echo "FIGMA_OAUTH_TOKEN=present (hidden)"
  else
    echo "FIGMA_OAUTH_TOKEN=missing"
  fi

  section "codex mcp get figma"
  if command -v "$CODEX_BIN" >/dev/null 2>&1; then
    "$CODEX_BIN" mcp get figma || true
  fi
}

repair_config() {
  if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
    echo "codex CLI not found on PATH" >&2
    exit 1
  fi

  mkdir -p "$CODEX_HOME_DIR"
  if [[ -f "$CONFIG_FILE" ]]; then
    local backup="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG_FILE" "$backup"
    echo "Backed up config to $backup"
  fi

  "$CODEX_BIN" mcp remove figma >/dev/null 2>&1 || true
  "$CODEX_BIN" mcp add figma --url "$FIGMA_MCP_URL" --oauth-resource "$FIGMA_MCP_URL"
  echo "Recreated figma MCP entry with oauth_resource=$FIGMA_MCP_URL"
}

login() {
  if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
    echo "codex CLI not found on PATH" >&2
    exit 1
  fi

  echo "Starting Figma MCP OAuth login. A browser window should open."
  "$CODEX_BIN" mcp login figma
}

open_token_page() {
  echo "Opening Figma token documentation."
  open "https://www.figma.com/developers/api#access-tokens"
}

case "${1:-}" in
  "")
    print_status
    ;;
  --repair-config)
    repair_config
    print_status
    ;;
  --login)
    login
    ;;
  --repair-and-login)
    repair_config
    login
    ;;
  --open-token-page)
    open_token_page
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
