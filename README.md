# cloudflare_ip_ddns 使用说明书

## 项目概述cloudflare_ip_ddns 是一个基于 CloudflareSpeedTest 工具的项目
功能：自动测速 Cloudflare CDN IP 并更新 DNS 记录或 Hosts 文件
目的：帮助用户获取最优 Cloudflare 节点 IP，提升网络访问体验
## 项目特点1. 自动测速：基于 CloudflareSpeedTest 对指定 IP 段测速，筛选最优 IP
2. DNS 自动更新：将最优 IP 自动更新到 Cloudflare DNS 记录
3. Hosts 自动替换：自动替换系统 Hosts 文件中的 Cloudflare CDN IP
4. 双栈支持：同时提供 IPv4 (ip.txt) 和 IPv6 (ipv6.txt) 地址段数据
5. 自动化部署：包含 GitHub Actions 配置，支持自动构建和推送 Docker 镜像
## 文件出处说明| 文件路径                                  | 说明内容                                          |
|-----------------------------------------|-------------------------------------------------|
| cfst_linux_amd64/使用+错误+反馈说明.txt    | CloudflareSpeedTest 工具的使用说明、错误处理及反馈方式        |
| cfst_linux_amd64/ip.txt                 | IPv4 地址段数据文件，包含多个 Cloudflare IPv4 网段          |
| cfst_linux_amd64/ipv6.txt               | IPv6 地址段数据文件，包含多个 Cloudflare IPv6 网段          |
| update_dns.sh                           | 将最优 IP 更新到 Cloudflare DNS 记录的脚本               |
| cfst_linux_amd64/cfst_hosts.sh          | 替换系统 Hosts 中 Cloudflare CDN IP 的脚本               |
| .github/workflows/build.yml             | GitHub Actions 配置文件，用于自动构建和推送 Docker 镜像      |
## 使用方法

### 一、准备工作# 克隆项目到本地
git clone https://github.com/kaige1116/cloudflare_ip_ddns.git
cd cloudflare_ip_ddns

# 安装必要工具
sudo apt install curl jq  # Debian/Ubuntu 系统
# 或
sudo yum install curl jq  # CentOS/RHEL 系统

# 配置 Cloudflare 环境变量（用于 update_dns.sh）
export CF_API_TOKEN="你的Cloudflare API令牌"
export CF_ZONE_ID="你的域名区域ID"
export CF_DOMAIN="需要更新的域名"
### 二、CloudflareSpeedTest 工具使用# 进入工具目录
cd cfst_linux_amd64

# 基本测速（使用默认IPv4地址段）
./cfst -f ip.txt -o result.txt

# 使用IPv6地址段测速
./cfst -f ipv6.txt -o result_ipv6.txt

# 直接指定IP进行测速
./cfst -ip 1.1.1.1,2606:4700::/32

# 更多参数查看帮助
./cfst -h
### 三、自动更新DNS记录（update_dns.sh）# 赋予执行权限
chmod +x update_dns.sh

# 执行脚本
./update_dns.sh

# 脚本执行流程：
# 1. 运行CloudflareSpeedTest测速并保存结果到result.txt
# 2. 提取前5个最优IP保存到top_ips.txt
# 3. 调用Cloudflare API创建/更新对应DNS记录
### 四、自动更新Hosts文件（cfst_hosts.sh）# 赋予执行权限
chmod +x cfst_hosts.sh

# 首次使用（会提示输入当前Hosts中的Cloudflare IP）
./cfst_hosts.sh

# 非首次使用（直接执行替换操作）
./cfst_hosts.sh

# 脚本执行流程：
# 1. 运行测速并保存结果到result_hosts.txt
# 2. 提取最优IP替换Hosts中原IP
# 3. 自动备份Hosts到/etc/hosts_backup
### 五、Docker镜像构建（GitHub Actions）# 工作流自动触发条件：
# 1. 推送到main分支
# 2. 创建PR到main分支

# 构建结果：
# 镜像将推送到GitHub Container Registry
# 镜像地址：ghcr.io/[用户名]/cloudflare-speedtest:latest
## 注意事项1. 测速时若平均延迟极低（如0.xx），可能是走了代理，需关闭代理后重新测速
2. 路由器上运行时，需关闭路由器内的代理或排除相关设置，否则结果可能不准确
3. 每次测速因随机选取IP，结果可能不同，属于正常现象
4. 电脑开机后第一次测速延迟可能偏高，建议正式测速前先进行一次简短测速
5. 使用脚本前，建议仔细阅读相关说明文档