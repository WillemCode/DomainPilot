#!/usr/bin/env bash

# Domain 飞行员

################################################
NGINX_BIN=nginx
# NGINX_CONFIG=/etc/nginx/nginx.conf
# NGINX_CONFIG_HOME=/etc/nginx
##################################################

VER=3.1.2
HOSTIP=`curl https://4.ipw.cn`
LOG_TIME=`date +%Y%m%d%H%S`
ACME_EMAIL="my@example.com"
ACME_ENTRY="$HOME/.acme.sh/acme.sh"
PROJECT_NAME="DomainPilot"
PROJECT_ENTRY="DomainPilot.sh"
PROJECT_HOME="$HOME/$PROJECT_NAME"
PROJECT_SECRET="$PROJECT_HOME/secret.config"
PROJECT_BACKUPS="$PROJECT_HOME/backups"
PROJECT_LOGS_PATH="$PROJECT_HOME/logs"
PROJECT_BLACKLIST="$PROJECT_HOME/blacklist.txt"
PROJECT_LOGS_FILE="$PROJECT_LOGS_PATH/$LOG_TIME.log"
PROJECT_ENTRY_BIN="$PROJECT_HOME/$PROJECT_ENTRY"
PROJECT_DOMAIN_FILE="$PROJECT_HOME/$PROJECT_NAME.config"

# 自动生成临时文件名
TMP_FILE=$(mktemp)
SECRET_TMP_FILE=$(mktemp)

# 日志函数
log_info() { echo -e "\033[34m$(date +'[%Y年 %m月 %d日 %A %H:%M:%S %Z]') INFO: $@\033[0m" 1>&2; }
log_error() { echo -e "\033[31m$(date +'[%Y年 %m月 %d日 %A %H:%M:%S %Z]') ERRO: $@\033[0m" 1>&2; }
log_warning() { echo -e "\033[33m$(date +'[%Y年 %m月 %d日 %A %H:%M:%S %Z]') WARN: $@\033[0m" 1>&2; }

usage() {
  echo -e "\nUsage: $0 [options]\n"
  echo "Options:"
  echo "  -h, --help           显示帮助信息."
  echo "  -v, --version        显示版本信息."
  echo "  -e, --exec           检查所有域名到期自动申请."
  echo "  -l, --list           查看所有域名证书配置详情."
  echo "  -d, --del            删除已经配置好的云端密钥."
  echo "  -a, --add            添加云端密钥, 验证域名所有权."
  echo "  -s, --specify        指定单个域名进行证书申请配置."
  echo -e "----------------------------------------------------\n  请根据需要选择相应的选项。\n"
}

# Version function
version() {
  echo "$PROJECT_NAME 飞行员 version $VER"
}

# 创建项目目录
for dir in "$PROJECT_HOME" "$PROJECT_BACKUPS" "$PROJECT_LOGS_PATH"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir" && log_info "创建项目目录 $dir 成功."
  fi
done

if [ ! -f $PROJECT_SECRET ]; then
  touch $PROJECT_SECRET
fi
if [ ! -f $PROJECT_BLACKLIST ]; then
  touch $PROJECT_BLACKLIST
fi

if [ -f $PROJECT_DOMAIN_FILE ]; then
  mv "$PROJECT_DOMAIN_FILE" "$PROJECT_BACKUPS/$LOG_TIME-$PROJECT_NAME"
fi

# 将所有输出（标准输出和错误输出）重定向到日志文件
exec > >(tee -a "$PROJECT_LOGS_FILE") 2>&1

if [ ! -f "$PROJECT_ENTRY_BIN" ]; then
  cp "$0" "$PROJECT_ENTRY_BIN"
  echo ". \"${PROJECT_ENTRY_BIN}.env\"" >> "$HOME/.bashrc"
  echo "alias $PROJECT_ENTRY=\"$PROJECT_ENTRY_BIN\"" >> "${PROJECT_ENTRY_BIN}.env"
  chmod +x "$PROJECT_ENTRY_BIN"
  CRON_JOB="30 2 * * * '$PROJECT_ENTRY_BIN -e' >/dev/null 2>&1"
  (crontab -l | grep -F "$CRON_JOB") || {
    (crontab -l; echo "$CRON_JOB") | crontab -
  }
fi

check_command() {
  retu_msg=$1
  info_msg=$2
  erro_msg=$3
  if [ $retu_msg -eq 0 ]; then
    if [[ ! $info_msg == "" ]]; then
      log_info "$info_msg"
    fi
  else
    if [[ ! $erro_msg == "" ]]; then
      log_error "$erro_msg"
      bash dingding.sh "Pilot 证书申请通知" "#### $erro_msg  \n  #### 请手动查看原因.  \n  ##### 主机IP: $HOSTIP" "$HOSTIP" >/dev/null 2>&1
      exit 100
    fi
    return 100
  fi
}

clean_backup() {
find ${PROJECT_BACKUPS} -type f -regextype posix-extended -regex ".*/[0-9]{12}-domainpilot" -printf '%T@\t%p\n' | sort -nr | cut -f2- | tail -n +11 | xargs -I {} rm -f "{}"
check_command $? "清理备份文件成功."  "清理备份文件失败."
find ${PROJECT_BACKUPS} -type f -regextype posix-extended -regex ".*/[0-9]{12}-secret" -printf '%T@\t%p\n' | sort -nr | cut -f2- | tail -n +11 | xargs -I {} rm -f "{}"
check_command $? "清理备份密钥成功."  "清理备份密钥失败."
find ${PROJECT_LOGS_PATH} -type f -regextype posix-extended -regex ".*/[0-9]{12}.log" -printf '%T@\t%p\n' | sort -nr | cut -f2- | tail -n +11 | xargs -I {} rm -f "{}"
check_command $? "清理日志文件成功."  "清理日志文件失败."
}

if [ ! -f $ACME_ENTRY ]; then
  log_info "正在安装 $ACME_ENTRY"
  curl -s https://get.acme.sh | sh -s email=$ACME_EMAIL >/dev/null 2>&1
  check_command $? "$ACME_ENTRY 脚本安装成功"  "$ACME_ENTRY 脚本安装失败, 请手动安装..."
fi

# 添加云端密钥
add_secret() {
  read -e -p "请输入 DNS API 平台 (阿里云: dns_ali / 华为云: dns_huaweicloud): " yun_cloud
  if [ $yun_cloud == "dns_ali" ]; then
    echo -e "请输入阿里云 Access Key (AK): \c"
    ak=''
    while : ;
    do
      read -n 1 -s -p "" input_ak
      if [ "$input_ak" ]; then
        ak=${ak}"$input_ak"
        echo -e "*\c"
      else
        echo
        break
      fi
    done
    echo -e "请输入阿里云 Secret Key (SK): \c"
    sk=''
    while : ;
    do
      read -n 1 -s -p "" input_sk
      if [ "$input_sk" ]; then
        sk=${sk}"$input_sk"
        echo -e "*\c"
      else
        echo
        break
      fi
    done
    read -e -p "请输入备注信息 (e.g., Aliyun):" description
    encrypted_data=$(echo "$ak,$sk" | base64 -w 0)
    echo "dns_ali,$description,$encrypted_data" >> "$PROJECT_SECRET"
    log_info "阿里云凭据添加成功."
  elif [ $yun_cloud == "dns_huaweicloud" ]; then
    echo -e "请输入华为云 Username (Your IAM Username): \c"
    username=''
    while : ;
    do
      read -n 1 -s -p "" input_us
      if [ "$input_us" ]; then
        username=${username}"$input_us"
        echo -e "*\c"
      else
        echo
        break
      fi
    done
    echo -e "请输入华为云 Password: \c"
    password=''
    while : ;
    do
      read -n 1 -s -p "" input_pw
      if [ "$input_pw" ]; then
        password=${password}"$input_pw"
        echo -e "*\c"
      else
        echo
        break
      fi
    done
    echo "请输入备注信息 (e.g., huaweicloud 对中文支持不友好, 建议使用英文或拼音):"
    read -r description
    encrypted_data=$(echo "$username,$password" | base64 -w 0)
    echo "dns_huaweicloud,$description,$encrypted_data" >> "$PROJECT_SECRET"
    log_info "华为云凭据添加成功."
  else
    log_error "输入错误."
    exit 1
  fi
}

# 删除云端密钥
delete_secret() {
  cat "$PROJECT_SECRET" | form_info
  read -e -p "输入要删除的凭证的描述: " description
  if [ $(grep -q "$description" "$PROJECT_SECRET") ]; then
    log_error "输入错误."
    exit 1
  fi
  if grep -q "$description" "$PROJECT_SECRET"; then
    log_info "匹配到以下内容, 请确认是否进行删除"
    grep "$description" "$PROJECT_SECRET" | form_info
    read -e -p "是否进行删除? (y/n): " confirm
    confirm_lower=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')  
    case "$confirm_lower" in  
      yes|y)  
        log_info "确认删除."  
        cp "$PROJECT_SECRET" "$PROJECT_BACKUPS/$LOG_TIME-secret"
        sed -i "/$description/d" "$PROJECT_SECRET"
        log_info "凭据已成功删除."
        ;;  
      no|n)  
        log_info "取消删除."  
        ;;  
      *)  
        log_error "输入无效，请输入 (y/n)"  
        ;;  
	esac
  else
    log_error "未找到给定描述的凭据."
  fi
}

form_info() {
awk -F ',' \
	-v table_s="+++++++++ ---|||" \
	-v color_s="${colors:-"-6,-3,-5"}" \
	'BEGIN{
	}{
		for(i=1;i<=NF;i++){
			# 每列最大长度
			cols_len[i]=cols_len[i]<length($i)?length($i):cols_len[i]
			# 每行每列值
			rows[NR][i]=$i
		}
		# 前后行状态
		if(NR==1){
			befor=0
		}else if(1==2){
			after=0
		}
		rows[NR][0] = befor "," NF
		befor=NF
	}END{
		# 颜色表
		color_sum = split(color_s,clr_id,",")
		if(color_sum==3){
			# 简易自定义模式
			for(i=1;i<=3;i++){
				if(color_s~"-"){
					clr_id[i] = color_var(clr_id[i])
				}else if(colors~"\033["){
					clr_id[i] = cclr_id[i]
				}
			}
			# 组建色表
			for(i=1;i<=16;i++){
				if(i<10){
					colors[i] = clr_id[1]
				}else if(i==10){
					colors[i] = clr_id[2]
				}else if(i>10){
					colors[i] = clr_id[3]
				}
			}
		}else if(color_sum==16){
			# 全自定义模式
			for(i=1;i<=16;i++){
				if(color_s~"-"){
					clr_id[i] = color_var(clr_id[i])
				}else if(colors~"\033["){
					clr_id[i] = cclr_id[i]
				}
				#colors[i] = clr_id[i]
			}
		}
		#split(color_s,colors,",")
		clr_end = "\033[0m"
			clr_font = colors[10]
			#clr_cross = colrs[2]
			#clr_blank = colors[3]
		# 制表符二维表并着色
		for(i=1;i<=length(table_s);i++){
			if(colors[i]=="")
				tbs[i] = substr(table_s,i,1)
			else
				tbs[i] = colors[i] substr(table_s,i,1) clr_end
			fi
		}
		# 绘制上边框
		top_line=line_val("top")
		# 绘制文本行
		# 绘制分隔行
		mid_line=line_val("mid")
		# 绘制下边框
		btm_line=line_val("btm")
		# 行最大总长度
		line_len_sum=0
		for(i=1;i<=length(cols_len);i++){
			line_len_sum=line_len_sum + cols_len[i] + 2
		}
		line_len_sum=line_len_sum + length(cols_len) - 1
		# 所有表格线预存（提高效率）
		title_top = line_val("title_top")
		top = line_val("top")
		title_mid = line_val("title_mid")
		title_btm_mid = line_val("title_btm_mid")
		title_top_mid = line_val("title_top_mid")
		mid = line_val("mid")
		title_btm = line_val("title_btm")
		btm = line_val("btm")
		# 绘制表格 2
		line_rows_sum=length(rows)
		for(i=1;i<=line_rows_sum;i++){
			# 状态值
			split(rows[i][0],status,",")
			befors=int(status[1])
			nows=int(status[2])
			if(i==1 && befors==0){
				# 首行时
				if(nows<=1){
					# 单列
					print title_top
					print line_val("title_txt",rows[i][1],line_len_sum)

				}else if(nows>=2){
					# 多列
					print top
					print line_val("txt",rows[i])

				}
			}else if(befors<=1){
				# 前一行为单列时
				if(nows<=1){
					# 单列
					print title_mid
					print line_val("title_txt",rows[i][1],line_len_sum)
				}else if(nows>=2){
					# 多列
					print title_btm_mid
					print line_val("txt",rows[i])
				}

			}else if(befors>=2){
				# 前一行为多列时
				if(nows<=1){
					# 单列
					print title_top_mid
					print line_val("title_txt",rows[i][1],line_len_sum)
				}else if(nows>=2){
					# 多列
					print mid
					print line_val("txt",rows[i])
				}
			}
			# 表格底边
			if(i==line_rows_sum && nows<=1){
				# 尾行单列时
				print title_btm
			}else if(i==line_rows_sum && nows>=2){
				# 尾行多列时
				print btm
			}
		}
	}
	function color_var(  color){
		# 颜色
		#local color=$1
		#case $color in
		if(color=="-1" ||color=="-black"){
			n=30
		}else if(color=="-2" || color=="-red"){
			n=31
		}else if(color=="-3" || color=="-green"){
			n=32
		}else if(color=="-4" || color=="-yellow"){
			n=33
		}else if(color=="-5" || color=="-blue"){
			n=34
		}else if(color=="-6" || color=="-purple"){
			n=35
		}else if(color=="-7" || color=="-cyan"){
			n=36
		}else if(color=="-8" || color=="-white"){
			n=37
		}else if(color=="-0" || color=="-reset"){
			n=0
		}else{
			n=0
		}
		return "\033[" n "m"
	}
	function line_val(   part,   txt,  cell_lens,  cell_len,  line,  i){
		# 更新本次行标
		if(part=="top"){
			tbs_l=tbs[7]
			tbs_m=tbs[8]
			tbs_r=tbs[9]
			tbs_b=tbs[11]
		}else if(part=="mid"){
			tbs_l=tbs[4]
			tbs_m=tbs[5]
			tbs_r=tbs[6]
			tbs_b=tbs[12]
		}else if(part=="txt"){
			tbs_l=tbs[14] tbs[10]
			tbs_m=tbs[10] tbs[15] tbs[10]
			tbs_r=tbs[10] tbs[16]
			tbs_b=tbs[10]
		}else if(part=="btm"){
			tbs_l=tbs[1]
			tbs_m=tbs[2]
			tbs_r=tbs[3]
			tbs_b=tbs[13]
		}else if(part=="title_top"){
			tbs_l=tbs[7]
			tbs_m=tbs[11]
			tbs_r=tbs[9]
			tbs_b=tbs[11]
		}else if(part=="title_top_mid"){
			tbs_l=tbs[4]
			tbs_m=tbs[2]
			tbs_r=tbs[6]
			tbs_b=tbs[12]
		}else if(part=="title_mid"){
			tbs_l=tbs[4]
			tbs_m=tbs[12]
			tbs_r=tbs[6]
			tbs_b=tbs[12]
		}else if(part=="title_txt"){
			tbs_l=tbs[14]
			tbs_m=tbs[15]
			tbs_r=tbs[16]
			tbs_b=tbs[10]
		}else if(part=="title_btm"){
			tbs_l=tbs[1]
			tbs_m=tbs[13]
			tbs_r=tbs[3]
			tbs_b=tbs[13]
		}else if(part=="title_btm_mid"){
			tbs_l=tbs[4]
			tbs_m=tbs[8]
			tbs_r=tbs[6]
			tbs_b=tbs[12]
		}
		# 制表符着色
		#	tbs_l = clr_cross tbs_l clr_end
		#	tbs_m = clr_cross tbs_m clr_end
		#	tbs_r = clr_cross tbs_r clr_end
		#	tbs_b = clr_blank tbs_b clr_end
		# title行只有一列文本
		if(part=="title_txt"){
			cols_count=1
		}else{
			cols_count=length(cols_len)
		}
		line_tail=""
		for(i=1;i<=cols_count;i++){
			# 定义当前单元格内容，长度
			if(part=="txt"){
				cell_tail=txt[i]
				cols_len_new=cols_len[i]-length(cell_tail)
			}else if(part=="title_txt"){
				# 单列居中
				cell_tail=txt
				cols_len_new = ( cell_lens - length(cell_tail) ) / 2
				cols_len_fix = ( cell_lens - length(cell_tail) ) % 2
				#print cols_len_new,cols_len_fix
			}else{
				cell_tail = ""
				cols_len_new = cols_len[i] + 2
			}
			# 单元格文本着色
			cell_tail = clr_font cell_tail clr_end
			# 单元格内空白补全
			if(part=="title_txt"){
				# 单列
				#cols_len_new=cols_len_new/2
				for(cell_len=1;cell_len<=cols_len_new;cell_len++){
					cell_tail= tbs_b cell_tail tbs_b
				}
				# 单列非偶长度补全
				if(cols_len_fix==1){
					cell_tail = cell_tail " "
				}
			}else{
				# 多列
				for(cell_len=1;cell_len<=cols_len_new;cell_len++){
					cell_tail=cell_tail tbs_b
				}
			}
			# 首格
			if(i==1){
				line_tail=line_tail cell_tail
			}else{
				# 中格
				line_tail=line_tail tbs_m cell_tail
			}
			# 尾格
			if(i==cols_count){
				line_tail=line_tail tbs_r
			}
		}
		# 返回行
		return tbs_l line_tail
	}
	'
}

# 初始化操作系统和Nginx路径
init_params() {
  if [ -f /etc/os-release ]; then
      OS=$(grep 'PRETTY_NAME' /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
  elif [ -f /etc/redhat-release ]; then
      OS=$(cat /etc/redhat-release)
      # 检查是否为 CentOS 6 或 RHEL 6
      if echo "$OS" | grep -qE "release 6"; then
        echo "抱歉, 当前系统版本 ($OS) 不兼容, 请升级至更高版本. "
        exit 1
      fi
  elif [ -f /etc/alpine-release ]; then
      OS="alpine"
  else
      log_error "抱歉, 暂不支持该操作系统."
      exit 1
  fi

  $NGINX_BIN -V > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      log_warning "没有在PATH中找不到nginx, 正在进行查找nginx..."
      pid=$(ps -e | grep nginx | grep -v 'grep' | head -n 1 | awk '{print $1}')
      if [ -n "$pid" ]; then
          NGINX_BIN=$(readlink -f /proc/"$pid"/exe)
          # 再次验证
          $NGINX_BIN -V > /dev/null 2>&1
          check_command $? "Nginx可执行文件路径: $NGINX_BIN" "没有检测到Nginx, 请确认已经安装了Nginx."
      else
        log_error "没有检测到Nginx, 请确认已经安装了Nginx."
        exit 1
      fi
  fi

  NGINX_VERSION=$($NGINX_BIN -v 2>&1 | awk -F ': ' '{print $2}' | head -n 1 | head -c 20)

  if [ -z "$NGINX_CONFIG" ]; then
    NGINX_CONFIG=$(ps -eo pid,cmd | grep nginx | grep master | grep '\-c' | awk -F '-c' '{print $2}' | sed 's/ //g')
  fi

  if [ -z "$NGINX_CONFIG"  ] || [ "$NGINX_CONFIG" = "nginx.conf" ]; then
    NGINX_CONFIG=$($NGINX_BIN -t 2>&1 | grep 'configuration' | head -n 1 | awk -F 'file' '{print $2}' | awk '{print $1}' )
  fi

  if [ -z "$NGINX_CONFIG_HOME" ]; then
    NGINX_CONFIG_HOME=$(dirname "$NGINX_CONFIG")
  fi

  if [ "$NGINX_CONFIG_HOME" = "." ]; then
    log_error "获取nginx配置文件失败."
    exit 0
  fi

  log_info "OS: $OS"
  log_info "Nginx Bin: $NGINX_BIN"
  log_info "Nginx Version: $NGINX_VERSION"
  log_info "Nginx Config: $NGINX_CONFIG"
  log_info "Nginx Config Home: $NGINX_CONFIG_HOME"
  #log_info "正在备份配置文件与证书..."
}

# 递归解析 include 文件
include_max_calls=20
include_global_count=0

process_include() {

  ((include_global_count++))

  if [ $include_global_count -gt $include_max_calls ]; then
      log_error "#######################################################"
      log_error "#####  warning: Maximum recursion limit reached.  #####"
      log_error "#######################################################"
      cat /dev/stdin
      return 0
  fi

  tmp=$(cat /dev/stdin | awk -v NGINX_CONFIG=">$NGINX_CONFIG:" -v NGINX_CONFIG_HOME="$NGINX_CONFIG_HOME" '{
      original = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      sub(/^[\t ]*|[\t ]*$/,"")
      if ($0 ~ /^>/) {
        print original
        next
      }
      if ($0 ~ /^#/) {
        print original
        next
      }
      if ($0 ~ /^include /) {
        if($0 ~ /mime\.types;/){
          print "#import " original
          next
        }
        print "#import " original
        gsub(/;/, "")
        if (substr($2, 1, 1) != "/") {
          $2 = NGINX_CONFIG_HOME "/" $2
        }
        cmd = "ls -1 " $2 " 2>/dev/null | xargs -I {} awk '\'' BEGIN {print \"#included-begin {};\" } {print}  END{ print \"#included-end {};\"  } '\'' {} "
        system(cmd)
        print ""
        next
      }
      print original
    }'
  )

  if echo "$tmp" | grep -v '#' | grep -q "include"; then
    # Perform a recursive call
    echo "$tmp" | process_include
  else
    # End the recursive call
    echo "$tmp"
  fi
}

parse_nginx_config() {
  config_text=$(cat $NGINX_CONFIG | process_include )
  echo "$config_text" > $TMP_FILE
  awk '
    BEGIN { server_name=""; ssl_cert=""; ssl_key=""; counter=1; }
    /^[ \t]*server_name[ \t]+/ {
      match($0, /^[ \t]*server_name[ \t]+([^;]+);/, arr)
      server_name = arr[1]
      gsub(/^[ \t]+|[ \t]+$/, "", server_name)
    }
    /^[ \t]*ssl_certificate[ \t]+/ {
      match($0, /^[ \t]*ssl_certificate[ \t]+([^;]+);/, arr)
      ssl_cert = arr[1]
      gsub(/^[ \t]+|[ \t]+$/, "", ssl_cert)
    }
    /^[ \t]*ssl_certificate_key[ \t]+/ {
      match($0, /^[ \t]*ssl_certificate_key[ \t]+([^;]+);/, arr)
      ssl_key = arr[1]
      gsub(/^[ \t]+|[ \t]+$/, "", ssl_key)
    }
    /}/ {
      if (server_name && ssl_cert && ssl_key) {
        split(server_name, names, /[ \t]+/)
        for (i in names) {
          print counter "," names[i] "," ssl_cert "," ssl_key >> "'$PROJECT_DOMAIN_FILE'"
          counter++
        }
      }
      server_name=""; ssl_cert=""; ssl_key=""
    }
  ' "$TMP_FILE"
  if [ ! -f "$PROJECT_DOMAIN_FILE" ]; then
    log_error "未找到 nginx 域名配置项."
    exit 110
  fi
}


## 证书详情
cert_info() {
  # 清空临时文件内容
  > "$TMP_FILE"
  echo "ID,DOMAIN,SSL_CERT,SSL_KEY,SUBJECT,START_DATE,END_DATE,DAYS_LEFT,APPLY_CERT" >> "$TMP_FILE"

  # 逐行读取文件
  while IFS=',' read -r id domain ssl_secret ssl_key; do
    if [ ! -f $ssl_secret ]; then
      echo "$id,$domain,$ssl_secret,$ssl_key, , , , ,Y" >> "$TMP_FILE"
    else
      # 提取证书持有者
      subject=$(openssl x509 -in "$ssl_secret" -noout -subject | sed 's/.*CN.*=\(.*\)/\1/')

      # 提取生效日期并格式化为 yyyy-mm-dd
      start_date=$(openssl x509 -in "$ssl_secret" -noout -startdate | cut -d= -f2)
      start_date_formatted=$(date -d "$start_date" +"%Y-%m-%d")

      # 提取到期时间并格式化为 yyyy-mm-dd
      end_date=$(openssl x509 -in "$ssl_secret" -noout -enddate | cut -d= -f2)
      end_date_formatted=$(date -d "$end_date" +"%Y-%m-%d")

      # 计算剩余有效期（天数）
      current_date=$(date +%s)
      end_date_epoch=$(date -d "$end_date" +%s)
      days_left=$(( (end_date_epoch - current_date) / 86400 ))
      if [ "$days_left" -lt 15 ]; then
        apply_cert="Y"
      else
        apply_cert="N"
      fi
      # 将提取的信息按格式追加到当前行
      echo "$id,$domain,$ssl_secret,$ssl_key,$subject,$start_date_formatted,$end_date_formatted,$days_left,$apply_cert" >> "$TMP_FILE"
    fi

  done < $PROJECT_DOMAIN_FILE

  # 用更新后的内容替换原始文件
  mv "$TMP_FILE" "$PROJECT_DOMAIN_FILE"
}


# 证书信息列表
list_cert_info() {
  awk -F',' 'BEGIN {OFS=","} {print $1,$2,$5,$6,$7,$8,$9}' "$PROJECT_DOMAIN_FILE" | form_info
}

# 使用云 DNS API 证书申请
yun_cert_application() {
  app_cert=$1
  app_domain=$2
  app_domain_cert=$3
  app_domain_key=$4
  yun_cloud=$5
  yun_describe=$6
  yun_option1=$7
  yun_option2=$8
  case $yun_cloud in
  dns_ali)
    export Ali_Key=$yun_option1
    export Ali_Secret=$yun_option2
    ;;
  dns_huaweicloud)
    export HUAWEICLOUD_Username=$yun_option1
    export HUAWEICLOUD_Password=$yun_option2
    export HUAWEICLOUD_DomainName=$app_domain
    ;;
  *)
    log_error "不支持的云服务提供商: $yun_cloud 跳过."
    return 1
    ;;
  esac

  if [[ "$app_cert" == "Y" ]]; then
    log_info "正在使用云 DNS API 申请证书. 目前账户: $yun_describe"
    log_info "$app_domain 正在申请证书."
    $ACME_ENTRY --issue --dns $yun_cloud -d $app_domain --log  >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
      return 1
    else
      log_info "$app_domain 证书申请成功."
      bash dingding.sh "Pilot 证书申请通知" "#### 证书申请成功: ${app_domain}" "${app_domain}" >/dev/null 2>&1
      log_info "$app_domain 正在进行安装证书..."
      $ACME_ENTRY --install-cert -d $app_domain --key-file $app_domain_key --fullchain-file $app_domain_cert  >/dev/null 2>&1
      check_command $? "$app_domain 证书安装成功" "$app_domain 证书安装失败"
      bash dingding.sh "Pilot 证书申请通知" "#### 证书安装成功: ${app_domain}" "${app_domain}" >/dev/null 2>&1
      $NGINX_BIN -t
      check_command $? "" "服务状态异常, 请进行检查并重载配置文件: $NGINX_BIN -s reload OR serviec nginx reload"
      $NGINX_BIN -s reload
      check_command $? "重载配置文件成功" "重载配置文件失败"
    fi
  fi
}

# 使用手动添加解析 证书申请
manual_cert_application() {
  app_cert=$1
  app_domain=$2
  app_domain_cert=$3
  app_domain_key=$4

  if [[ "$app_cert" == "Y" ]]; then
    log_info "正在通过手动添加解析记录, 验证域名所有权, 请稍候..."
    log_warning "$app_domain 请根据以下提示手动添加解析记录, 验证域名所有权."
    $ACME_ENTRY --issue --dns -d $app_domain --yes-I-know-dns-manual-mode-enough-go-ahead-please --log | grep -E "Domain:|TXT value:"
    check_command $? "请根据以上提示, 手动添加 TXT 解析记录, 进行域名验证." "$app_domain 申请解析记录失败, 请手动检查原因..."
    log_info "等待一分钟后继续..." && sleep 6
    $ACME_ENTRY --renew -d $app_domain --yes-I-know-dns-manual-mode-enough-go-ahead-please
    check_command $? "$app_domain 证书申请成功." "$app_domain 证书申请失败, 请手动添加 TXT 解析记录后重试."
    bash dingding.sh "Pilot 证书申请通知" "#### 证书申请成功: ${app_domain}" "${app_domain}" >/dev/null 2>&1
    log_info "$app_domain 正在进行安装证书..."
    $ACME_ENTRY --install-cert -d $app_domain --key-file $app_domain_key --fullchain-file $app_domain_cert  >/dev/null 2>&1
    check_command $? "$app_domain 证书安装成功" "$app_domain 证书安装失败"
    bash dingding.sh "Pilot 证书申请通知" "#### 证书安装成功: ${app_domain}" "${app_domain}" >/dev/null 2>&1
    $NGINX_BIN -t
    check_command $? "" "服务状态异常, 请进行检查并重载配置文件: $NGINX_BIN -s reload OR serviec nginx reload"
    $NGINX_BIN -s reload
    check_command $? "重载配置文件成功" "重载配置文件失败"
  fi
}

cert_application() {
  specified_domain=$1
  yuncloud_SecretKey=$2
  secret_num=$(grep "," "$PROJECT_SECRET" | wc -l)
  if [[ "$secret_num" == "0" ]]; then
    while IFS=',' read -r app_nmb app_domain app_domain_cert app_domain_key _ _ _ _ app_cert; do
      domain_num=$(grep "$app_domain" "$PROJECT_BLACKLIST" | wc -l)
      if [[ "$specified_domain" && "$app_domain" != "$specified_domain" ]]; then
        continue
      fi
      if [[ "$app_nmb" == "ID" ]]; then
        continue
      elif [[ ! "$domain_num" == "0" ]]; then
        log_warning "域名在黑名单中, 已跳过 $PROJECT_BLACKLIST Exist $app_domain ."
        continue
      fi
      manual_cert_application "$app_cert" "$app_domain" "$app_domain_cert" "$app_domain_key"
    done < "$PROJECT_DOMAIN_FILE"
  else
    while IFS=',' read app_nmb app_domain app_domain_cert app_domain_key _ _ _ _ app_cert; do
      if [[ "$yuncloud_SecretKey" == "" ]]; then
        count=1
        while IFS=',' read yun_cloud yun_describe decrypted_line; do
          decrypted_line=$(echo "$decrypted_line" | base64 --decode)
          yun_option1=$(echo "$decrypted_line" | awk -F',' '{print $1}')
          yun_option2=$(echo "$decrypted_line" | awk -F',' '{print $2}')
          domain_num=$(grep "$app_domain" "$PROJECT_BLACKLIST" | wc -l)
          if [[ "$specified_domain" && "$app_domain" != "$specified_domain" ]]; then
            continue
          fi
          if [[ "$app_nmb" == "ID" ]]; then
            continue
          elif [[ ! "$domain_num" == "0" ]]; then
            log_warning "域名在黑名单中, 已跳过 $PROJECT_BLACKLIST Exist $app_domain ."
            continue
          fi
          yun_cert_application "$app_cert" "$app_domain" "$app_domain_cert" "$app_domain_key" "$yun_cloud" "$yun_describe" "$yun_option1" "$yun_option2"
          if [ ! $? -eq 0 ]; then
            if [[ "$count" == "$secret_num" ]]; then
              log_error "$app_domain 使用云 DNS API 证书申请失败."
              manual_cert_application "$app_cert" "$app_domain" "$app_domain_cert" "$app_domain_key"
            fi
          else
            break
          fi
          ((count++))
        done < "$PROJECT_SECRET"
      else
        count=1
        while IFS=',' read yun_cloud yun_describe decrypted_line; do
          decrypted_line=$(echo "$decrypted_line" | base64 --decode)
          yun_option1=$(echo "$decrypted_line" | awk -F',' '{print $1}')
          yun_option2=$(echo "$decrypted_line" | awk -F',' '{print $2}')
          domain_num=$(grep "$app_domain" "$PROJECT_BLACKLIST" | wc -l)
          if [[ "$specified_domain" && "$app_domain" != "$specified_domain" ]]; then
            continue
          fi
          if [[ "$app_nmb" == "ID" ]]; then
            continue
          elif [[ ! "$domain_num" == "0" ]]; then
            log_warning "域名在黑名单中, 已跳过 $PROJECT_BLACKLIST Exist $app_domain ."
            continue
          fi
          if [[ $yun_describe == $yuncloud_SecretKey ]]; then
            yun_cert_application "$app_cert" "$app_domain" "$app_domain_cert" "$app_domain_key" "$yun_cloud" "$yun_describe" "$yun_option1" "$yun_option2"
            if [ ! $? -eq 0 ]; then
              if [[ "$count" == "$secret_num" ]]; then
                log_error "未找到指定的云 DNS API 记录, 请添加后重试."
              fi
            else
              break
            fi
          fi
          ((count++))
        done < "$PROJECT_SECRET"
      fi
    done < "$PROJECT_DOMAIN_FILE"
  fi
}

# 主函数
main() {
  if [[ "$#" -eq 0 ]]; then
    usage
    exit 0
  fi
  while [[ "$1" != "" ]]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      -l | --list)
        init_params
        clean_backup
        parse_nginx_config
        cert_info
        list_cert_info
        exit 0
        ;;
      -e | --exec)
        init_params
        clean_backup
        log_info "检查所有域名证书配置，自动申请即将到期的证书."
        parse_nginx_config
        cert_info
        #list_cert_info
        cert_application
        ;;
      -a | --add)
        add_secret
        exit 0
        ;;
      -d | --del)
        delete_secret
        clean_backup
        exit 0
        ;;
      -s | --specify)
        shift
        specify_domain=$1
        yuncloud_SecretKey=$2
        if [[ -z "$specify_domain" ]]; then
          log_error "错误: 必须提供域名参数。"
          usage
          exit 1
        fi
        init_params
        clean_backup
        parse_nginx_config
        cert_info
        #list_cert_info
        log_info "密钥配置较多的情况下, 可手动指定密钥进行快速申请"
        log_warning "密钥配置信息如下: "
        cat "$PROJECT_SECRET" | form_info
        cert_application "$specify_domain" "$yuncloud_SecretKey"
        exit 0
        ;;
      *)
        log_error "错误: 无效的选项 '$1'"
        usage
        exit 1
    esac
    shift
  done
}

main "$@"

