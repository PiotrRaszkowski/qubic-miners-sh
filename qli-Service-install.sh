#!/usr/bin/bash

if [ -z "$1" ] || [ -z "$2" ]
  then
    echo "Need at least two arguments."
    echo "Usage: install.sh <NUMBEROFTHREADS> <TOKEN> [ALIAS]"
    echo "<NUMBEROFTHREADS>: The number uf threads to be used by this client"
    echo "<TOKEN>: Your personal token to access the API"
    echo "[ALIAS] (OPTIONAL): The name of this client. If empty hostname will be used."
    exit 1
fi

#private settings
token=$2
threads=$1
minerAlias=$3

#public settings
currentPath=`pwd`
path=/q
package=qli-Client-1.9.6-Linux-x64.tar.gz
executableName=qli-Client
serviceScript=qli-Service.sh
servicePath=/etc/systemd/system
qubicService=qli.service
settingsFile=appsettings.json

#stop service if it is running
systemctl is-active --quiet qli && systemctl stop --no-block qli

#install
[ ! -d "/q/" ] && mkdir $path
cd $path
# remove lock files
rm $path/qli-runner.lock
# remove existing solutions
rm $path/*.e*
# remove existing runners/flags
[ -f "$path/qli-runner" ] && rm $path/qli-runner
[ -f "$path/qli-processor" ] && rm $path/qli-processor
# remove installation file
[ -f "$package" ] && rm $package
wget -4 -O $package https://dl.qubic.li/downloads/$package
tar -xzvf $package
rm $package
rm $path/$settingsFile
if [ ${#token} -ge 61 ]; then
  echo "{\"Settings\":{\"baseUrl\": \"https://mine.qubic.li/\",\"amountOfThreads\": $threads,\"alias\": \"$minerAlias\",\"accessToken\": \"$token\", \"autoupdateEnabled\": false}}" > $path/$settingsFile;
else
  echo "{\"Settings\":{\"baseUrl\": \"https://mine.qubic.li/\",\"amountOfThreads\": $threads,\"alias\": \"$minerAlias\",\"accessToken\": null,\"payoutId\": \"$token\", \"autoupdateEnabled\": false}}" > $path/$settingsFile;
fi
echo -e "[Unit]\nAfter=network-online.target\n[Service]\nStandardOutput=append:/var/log/qli.log\nStandardError=append:/var/qli.error.log\nExecStart=/bin/bash $path/$serviceScript\nRestart=on-failure\nRestartSec=1s\n[Install]\nWantedBy=default.target" > $servicePath/$qubicService
chmod u+x $path/$serviceScript
chmod u+x $path/$executableName
chmod 664 $servicePath/$qubicService
systemctl daemon-reload
systemctl enable --no-block $qubicService
systemctl start --no-block $qubicService
cd $currentPath
[ -f "qli-Service-install.sh" ] && rm qli-Service-install.sh