#!/bin/bash

# 运行测速
echo "开始执行 Cloudflare IP 测速..."
./cfst -f ip.txt -o result.txt

# 获取前5个最优IP
echo "获取最优IP列表..."
head -n 7 result.txt | tail -n 6 | awk -F, '{print $1}' > top_ips.txt

# 调用Cloudflare API更新DNS记录
update_dns() {
  local ip_index=$1
  local ip_address=$2
  
  # Cloudflare API调用逻辑
  echo "更新 ip${ip_index}.${CF_DOMAIN} 为 ${ip_address}"
  
  # 获取现有DNS记录ID
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=ip${ip_index}.${CF_DOMAIN}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')
  
  # 更新或创建DNS记录
  if [ "$RECORD_ID" != "null" ]; then
    # 更新现有记录
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"type":"A","name":"ip'${ip_index}'.'${CF_DOMAIN}'","content":"'${ip_address}'","ttl":120,"proxied":false}'
  else
    # 创建新记录
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"type":"A","name":"ip'${ip_index}'.'${CF_DOMAIN}'","content":"'${ip_address}'","ttl":120,"proxied":false}'
  fi
}

# 读取IP并更新DNS
index=1
while IFS= read -r ip; do
  if [ -n "$ip" ]; then
    update_dns $index "$ip"
    index=$((index + 1))
  fi
done < top_ips.txt

echo "DNS更新完成"
