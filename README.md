###CloudflareSpeedTest项目的docker版本
docker compose配置说明
services:
  cfst:
    container_name: cloudflare_ip_ddns
    image: ghcr.io/kaige1116/cloudflare-speedtest:latest
    restart: always
    environment:
      # Cloudflare API 配置
      - CF_API_TOKEN=API_TOKEN
      - CF_ZONE_ID=区域ID
      - CF_DOMAIN=主域名
      
      # 测速配置
      - CFST_PARAMS=-f ip.txt -p 443 -t 10 -tl 200
      - IP_COUNT=6  # 保留的IP数量
      
      # 定时任务配置 (默认7天)
      - UPDATE_INTERVAL=7d
    volumes:
      - ./logs:/var/log
      - ./results:/app/results
    platform: linux/amd64  # 针对x86平台
	
	利用docker运行CloudflareSpeedTest进行本地IP优选，后自动更新到cloudfalre。
	默认格式：ip1.yuming.com,ip2.yuming.com,ip3.yuming.com,ip4.yuming.com,ip5.yuming.com,ip6.yuming.com,
	
	工具引用：https://github.com/XIU2/CloudflareSpeedTest/releases/tag/v2.3.4