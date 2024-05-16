#!/bin/bash
apiLoginResponse="$(/usr/bin/curl -s -d '{"userName":"guest@qubic.li", "password":"guest13@Qubic.li"}' -H "Content-Type: application/json" -X POST https://api.qubic.li/Auth/Login)"
apiToken=$(echo "$apiLoginResponse" | jq -r .token)
tickOverviewResponse=$(/usr/bin/curl -s -H "Authorization: Bearer $apiToken" -H "Content-Type: application/json" 'https://api.qubic.li/Network/TickOverview?epoch=&offset=0')

priceThresholdMin="0.00000491"
tickOverviewPrice=$(echo "$tickOverviewResponse" | jq -r .price)

echo "Min: $priceThresholdMin"
echo "Price: $tickOverviewPrice"

if (( $(echo "$tickOverviewPrice >= $priceThresholdMin" | bc -l) )); then
  echo "ok!";
fi

