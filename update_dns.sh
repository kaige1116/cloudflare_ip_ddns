#!/bin/bash
set -x  # 开启命令执行日志输出

# 运行测速
echo "[$(date)] 开始执行 Cloudflare IP 测速..."
./cfst -f ip.txt -o result.txt || echo "[$(date)] 测速命令执行失败"

# 查看结果文件前几行，便于调试
echo "[$(date)] 测速结果前10行："
head -n 10 result.txt

# 获取前6个最优IP
echo "[$(date)] 获取最优IP列表..."
head -n 7 result.txt | tail -n 6 | awk -F, '{print $1}' > top_ips.txt

# 显示获取到的IP列表
echo "[$(date)] 本次优选的IP列表："
cat top_ips.txt

# 调用Cloudflare API更新DNS记录
update_dns() {
  local ip_index=$1
  local ip_address=$2
  
  echo "[$(date)] 开始更新 ip${ip_index}.${CF_DOMAIN} 为 ${ip_address}"
  
  # 获取现有DNS记录ID
  echo "[$(date)] 查询现有DNS记录ID..."
  RECORD_RESPONSE=$(curl -v "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=ip${ip_index}.${CF_DOMAIN}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json")
  
  # 显示API响应
  echo "[$(date)] API查询响应：${RECORD_RESPONSE}"
  
  RECORD_ID=$(echo ${RECORD_RESPONSE} | jq -r '.result[0].id')
  echo "[$(date)] 获取到的记录ID：${RECORD_ID}"
  
  # 更新或创建DNS记录
  if [ "$RECORD_ID" != "null" ] && [ -n "$RECORD_ID" ]; then
    # 更新现有记录
    echo "[$(date)] 更新现有记录 ${RECORD_ID}..."
    UPDATE_RESPONSE=$(curl -v -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"type":"A","name":"ip'${ip_index}'.'${CF_DOMAIN}'","content":"'${ip_address}'","ttl":120,"proxied":false}')
    
    echo "[$(date)] 更新响应：${UPDATE_RESPONSE}"
  else
    # 创建新记录
    echo "[$(date)] 创建新记录..."
    CREATE_RESPONSE=$(curl -v -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"type":"A","name":"ip'${ip_index}'.'${CF_DOMAIN}'","content":"'${ip_address}'","ttl":120,"proxied":false}')
    
    echo "[$(date)] 创建响应：${CREATE_RESPONSE}"
  fi
}

# 读取IP并更新DNS
index=1
while IFS= read -r ip; do
  if [ -n "$ip" ]; then
    update_dns $index "$ip"
    index=$((index + 1))
  else
    echo "[$(date)] 发现空IP记录，跳过"
  fi
done < top_ips.txt

echo "[$(date)] DNS更新流程完成"
    