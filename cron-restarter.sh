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
echo "Home directory: $(HOME)"
/usr/bin/git pull

if [ ! -d "$miner" ]; then
  echo "$miner does not exist, exiting."
  exit 1;
fi

if [ -f "$miner/config.json" ]; then
    enabled="$(jq .enabled "$miner/config.json")"
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