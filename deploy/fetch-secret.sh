#!/bin/bash
# busca a connection string no Key Vault usando a identidade gerenciada da VM
set -euo pipefail
VAULT="kv-techstore-lucas"
SECRET="ConnectionStrings--DefaultConnection"

TOKEN=$(curl -s -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" | jq -r .access_token)

VALOR=$(curl -s -H "Authorization: Bearer $TOKEN" "https://${VAULT}.vault.azure.net/secrets/${SECRET}?api-version=7.4" | jq -r .value)

if [ -z "$VALOR" ] || [ "$VALOR" = "null" ]; then
  echo "nao consegui ler o segredo do Key Vault" >&2
  exit 1
fi

umask 077
printf 'ConnectionStrings__DefaultConnection=%s\n' "$VALOR" > /run/techstore-secrets.env
