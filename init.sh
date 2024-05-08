#!/bin/bash

minerPath=$1
if [ -z "$minerPath" ]; then
  echo "Miner path is required."
  exit 1;
fi

cd $minerPath

git init
git remote add origin git@github.com:PiotrRaszkowski/qubic-miners.git
git fetch
git checkout -t origin/main