#!/bin/bash
set -e  # 出错时立即退出，避免继续执行

# 定义输出路径（与Docker挂载路径对应）
LOG_PATH="/var/log/cfst_update.log"  # 对应本地./logs
RESULTS_PATH="/app/results"          # 对应本地./results

# 确保目录存在
mkdir -p $RESULTS_PATH $TOP_IPS_PATH

# 日志函数（同时输出到控制台和文件）
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo $msg
  echo $msg >> $LOG_PATH  # 写入日志文件
}

# 简化日志输出，只保留关键步骤
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 运行测速
log "开始执行Cloudflare IP测速..."
./cfst -f ip.txt -o result.txt || { log "测速失败！"; exit 1; }

# 获取前6个最优IP
log "获取前6个最优IP..."
head -n 7 result.txt | tail -n 6 | awk -F, '{print $1}' > top_ips.txt
log "本次优选IP列表："
cat top_ips.txt | while read ip; do log "  - $ip"; done

# 调用Cloudflare API更新DNS记录
update_dns() {
  local ip_index=$1
  local ip_address=$2
  local record_name="ip${ip_index}.${CF_DOMAIN}"
  
  log "开始更新 ${record_name} → ${ip_address}"
  
  # 查询现有记录（关闭curl冗余输出）
  RECORD_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=${record_name}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json")
  
  # 解析记录ID
  RECORD_ID=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].id')
  
  # 更新或创建记录
  if [ "$RECORD_ID" != "null" ] && [ -n "$RECORD_ID" ]; then
    # 更新现有记录
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"type":"A","name":"'${record_name}'","content":"'${ip_address}'","ttl":120,"proxied":false}')
  else
    # 创建新记录
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"type":"A","name":"'${record_name}'","content":"'${ip_address}'","ttl":120,"proxied":false}')
  fi
  
  # 检查结果
  if echo "$RESPONSE" | jq -r '.success' | grep -q "true"; then
    log "${record_name} 更新成功"
  else
    log "${record_name} 更新失败！响应: ${RESPONSE}"
    exit 1
  fi
}

# 批量更新6个IP
index=1
while IFS= read -r ip; do
  if [ -n "$ip" ]; then
    update_dns $index "$ip"
    index=$((index + 1))
  else
    log "跳过空IP记录"
  fi
done < top_ips.txt

log "所有DNS记录更新完成"