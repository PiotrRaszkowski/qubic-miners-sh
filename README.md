sudo apt-get install keychain

ssh-keygen -t ed25519 -C "root@ussvoyager"

eval `keychain --eval --agents ssh id_ed25519`

Host github.com
    AddKeysToAgent yes
    IgnoreUnknown UseKeychain
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519

git init
git remote add origin git@github.com:PiotrRaszkowski/qubic-miners.git
fit fetch
git checkout -t origin/main

curl -s "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/init.sh" | bash

*/15 * * * * curl -s "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/cron-updater.sh" | bash -s ussenterprise /q