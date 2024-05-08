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

echo "Updating $miner in $(pwd)..."

cd $minerPath
echo "Current directory: $(pwd)"

if [ ! -d "$miner" ]; then
  echo "$miner does not exist, exiting."
  exit 1;
fi

echo "Pulling latest changes..."
git pull

minerVersion="`cat .minerVersion`"

if test -f ".lastMinerVersion"; then
    lastMinerVersion="$(cat .lastMinerVersion)"
else
    lastMinerVersion="<unknown>"
fi

echo "Current version: $minerVersion, last version: $lastMinerVersion."

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

    systemctl restart $serviceName

    rm "qli-Client-$minerVersion-Linux-x64.tar.gz"
else
  if test -f ".lastConfigurationVersion"; then
      lastConfigurationVersion="$(cat .lastConfigurationVersion)"
  else
      lastConfigurationVersion="<unknown>"
  fi

  newConfigurationVersion=$(shasum "$miner/appsettings.production.json")

  if [ "$newConfigurationVersion" != "$lastConfigurationVersion" ]; then
      echo "Configuration changed from $lastConfigurationVersion to $newConfigurationVersion"

      cp "$miner/appsettings.production.json" appsettings.production.json
  fi

  if [ -f "$miner/.hugePages" ]; then
    hugePages="$(cat "$miner/.hugePages")"

    echo "Setting huge pages to $hugePages"

    /usr/sbin/sysctl -w vm.nr_hugepages=$hugePages
  fi

  systemctl restart $serviceName
fi

echo "$minerVersion" > .lastMinerVersion
echo "$newConfigurationVersion" > .lastConfigurationVersion