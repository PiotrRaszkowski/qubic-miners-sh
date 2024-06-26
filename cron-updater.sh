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

    if [ "$tickOverviewPrice" == "null" ]; then
      echo "Failed to get price from API, exiting."
      exit 1;
    fi

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

serviceStatus="$(systemctl is-active "$serviceName")"

if [ "$serviceStatus" != "active" ]; then
    echo "Service is not active, starting..."
    systemctl start $serviceName
fi

##################################### UPDATE MINER #####################################
if test -f ".lastMinerVersion"; then
    lastMinerVersion="$(cat .lastMinerVersion)"
else
    lastMinerVersion="<unknown>"
fi

if [ -f "$miner/config.json" ]; then
  minerVersion="$(jq -r .minerVersion "$miner/config.json")"
else
  minerVersion="$(cat .minerVersion)"
fi

echo "Current version: $minerVersion, last version: $lastMinerVersion."

echo "Cleaning up old miner files..."
rm -f *.tar.gz *.tar.gz.[0-9]

if [ "$minerVersion" != "$lastMinerVersion" ]; then
    echo "Miner version changed from $lastMinerVersion to $minerVersion"

    wget "https://dl.qubic.li/downloads/qli-Client-$minerVersion-Linux-x64.tar.gz"

    tar -xvf "qli-Client-$minerVersion-Linux-x64.tar.gz"

    cp "$miner/appsettings.production.json" appsettings.production.json

    sed "s/\[PATH\]/${minerPath//\//\\/}/g" placeholder.qli-Service.sh > qli-Service.sh

    if [ -f "$miner/.hugePages" ]; then
      hugePages="$(cat "$miner/.hugePages")"

      echo "Setting huge pages to $hugePages"

      /usr/sbin/sysctl -w vm.nr_hugepages=$hugePages
    fi

    echo "Restarting $serviceName..."
    systemctl restart $serviceName

    rm "qli-Client-$minerVersion-Linux-x64.tar.gz"
else
  if [ -f "$miner/.hugePages" ]; then
    hugePages="$(cat "$miner/.hugePages")"

    echo "Setting huge pages to $hugePages"

    /usr/sbin/sysctl -w vm.nr_hugepages=$hugePages
  fi

  if test -f ".lastConfigurationVersion"; then
      lastConfigurationVersion="$(cat .lastConfigurationVersion)"
  else
      lastConfigurationVersion="<unknown>"
  fi

  newConfigurationVersion=$(shasum "$miner/appsettings.production.json")

  if [ "$newConfigurationVersion" != "$lastConfigurationVersion" ]; then
      echo "Configuration changed from $lastConfigurationVersion to $newConfigurationVersion"

      cp "$miner/appsettings.production.json" appsettings.production.json

      echo "Restarting $serviceName..."
      systemctl restart $serviceName
  fi
fi

echo "$minerVersion" > .lastMinerVersion
echo "$newConfigurationVersion" > .lastConfigurationVersion