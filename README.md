```bash
apt-get install keychain
```

```bash
ssh-keygen -t ed25519 -C "root@ussvoyager"
```

```bash
eval `keychain --eval --agents ssh id_ed25519`
```

```bash
echo 'eval `keychain --eval --agents ssh id_ed25519`' >> ~/.bashrc
```

```bash
echo 'Host github.com
    AddKeysToAgent yes
    IgnoreUnknown UseKeychain
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519' >> ~/.ssh/config
```

```bash
curl -s -H 'Pragma: no-cache' "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/init.sh" | bash -s /q-gpu
```

```bash
curl -s -H 'Pragma: no-cache' "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/cron-updater.sh" | bash -s ussenterprise /q
```

```text
0 */4 * * * curl -s -H 'Pragma: no-cache' "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/cron-restarter.sh" | bash -s ussenterprise /q
*/15 * * * * curl -s -H 'Pragma: no-cache' "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/cron-updater.sh" | bash -s ussenterprise /q
```

curl -s -H 'Pragma: no-cache' "https://raw.githubusercontent.com/PiotrRaszkowski/qubic-miners-sh/main/cron-updater.sh" | bash -s birdofprey-gpu /q-gpu qli-gpu

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