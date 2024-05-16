#!/bin/bash

miner=$1
minerPath=$2
serviceName=$3

if [ -z "$miner" ]; then
  echo "Miner name is required."
  exit 1;
fi

if [ -z "$minerPath" ]; then
  echo "Miner path is required."
  exit 1;
fi

if [ -z "$serviceName" ]; then
  serviceName="qli"
  echo "Service name is not provided, using default: $serviceName"
fi

cd $minerPath
echo "Current directory: $(pwd)"

echo "Updating $miner in $(pwd)..."

echo "Pulling latest changes..."
HOME=/root
echo "Home directory: $HOME"
eval `keychain --eval --agents ssh id_ed25519`
/usr/bin/git fetch
/usr/bin/git reset --hard origin/main

if [ ! -d "$miner" ]; then
  echo "$miner does not exist, exiting."
  exit 1;
fi

if [ -f "$miner/config.json" ]; then
  cat "$miner/config.json"

  enabled="$(jq .enabled "$miner/config.json")"

  priceThresholdEnabled="$(jq .priceThresholdEnabled "$miner/config.json")"
  if [ "$priceThresholdEnabled" == "true" ]; then
    priceThresholdMin="$(jq -r .priceThresholdMin "$miner/config.json")"

    echo "Price threshold is set to $priceThresholdMin"

    apiLoginResponse="$(/usr/bin/curl -s -d '{"userName":"guest@qubic.li", "password":"guest13@Qubic.li"}' -H "Content-Type: application/json" -X POST https://api.qubic.li/Auth/Login)"
    apiToken=$(echo "$apiLoginResponse" | jq -r .token)
    tickOverviewResponse=$(/usr/bin/curl -s -H "Authorization: Bearer $apiToken" -H "Content-Type: application/json" 'https://api.qubic.li/Network/TickOverview?epoch=&offset=0')
    tickOverviewPrice=$(echo "$tickOverviewResponse" | jq -r .price)

    echo "Current price is: $tickOverviewPrice"

    if awk "BEGIN {exit !($tickOverviewPrice >= $priceThresholdMin)}"; then
      echo "$tickOverviewPrice is ge $priceThresholdMin, miner will be enabled"
      enabled="true"
    else
      echo "$tickOverviewPrice is lt $priceThresholdMin, miner will be disabled"
      enabled="false"
    fi
  else
    echo "Price threshold validation is not enabled, skipping."
  fi
else
  enabled="true"
fi

echo "Enabled = $enabled"

if [ "$enabled" != "true" ]; then
    echo "$miner is disabled, stopping service and exiting."
    systemctl stop $serviceName
    exit 0;
fi

systemctl stop $serviceName
systemctl start $serviceName