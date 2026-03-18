#!/bin/bash

# --- [顏色與基礎路徑] ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
REAL_USER=${SUDO_USER:-$(whoami)}

# --- [1. 系統基礎工具] ---
fn_1_system_base() {
    echo -e "${YELLOW}正在更新系統並安裝基礎工具 (Git, Curl)...${NC}"
    sudo apt update && sudo apt install -y curl git build-essential jq unzip
}

# --- [2. 安裝 Nginx] ---
fn_2_install_nginx() {
    echo -e "${YELLOW}正在安裝 Nginx 網頁伺服器...${NC}"
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo -e "${GREEN}✅ Nginx 已啟動。${NC}"
}

# --- [3. 安裝 PHP 8.3] ---
fn_3_install_php() {
    echo -e "${YELLOW}正在安裝 PHP 8.3 與 Laravel 必要擴展...${NC}"
    sudo apt install -y php8.3 php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-gd php8.3-intl
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
}

# --- [4. 安裝 Node.js v22] ---
fn_4_install_node() {
    echo -e "${YELLOW}正在安裝 Node.js v22 與 pnpm...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo npm install -g pnpm
}

# --- [5. 安裝 MySQL Server] ---
fn_5_install_mysql() {
    echo -e "${YELLOW}正在安裝 MySQL Server...${NC}"
    sudo apt install -y mysql-server
    sudo systemctl start mysql
    sudo systemctl enable mysql
}

# --- [6. 設定 MySQL Root 密碼 (A123456a)] ---
fn_6_mysql_root_setup() {
    echo -e "${YELLOW}正在設定 MySQL Root 密碼為 A123456a...${NC}"
    sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'A123456a';
FLUSH PRIVILEGES;
EOF
    echo -e "${GREEN}✅ Root 密碼設定成功。${NC}"
}

# --- [7. 獨立功能：僅建立資料庫] ---
fn_7_mysql_create_db() {
    echo -e "${GREEN}--- 建立新資料庫 ---${NC}"
    read -p "請輸入要建立的資料庫名稱: " NEW_DB
    mysql -u root -pA123456a -e "CREATE DATABASE IF NOT EXISTS $NEW_DB;"
    echo -e "${GREEN}✅ 資料庫 [$NEW_DB] 建立成功。${NC}"
}

# --- [8. 獨立功能：僅建立使用者並授權] ---
fn_8_mysql_add_user() {
    echo -e "${GREEN}--- 建立 MySQL 使用者與權限分配 ---${NC}"
    read -p "請輸入新使用者名稱: " DB_USER
    read -p "請輸入該使用者密碼: " DB_PASS
    read -p "請輸入要授權的資料庫名稱 (若要授權全部請輸入 *): " TARGET_DB
    
    echo -e "${YELLOW}正在建立使用者並配置權限...${NC}"
    mysql -u root -pA123456a <<EOF
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $TARGET_DB.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF
    echo -e "${GREEN}✅ 使用者 [$DB_USER] 建立成功，並已獲得 [$TARGET_DB] 的權限。${NC}"
}

# --- [🕹️ 戰術選單] ---
show_menu() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "    🦞 GAPOON 模組化部署腳本 V4.1"
    echo -e "${GREEN}==========================================${NC}"
    echo -e " 1) 系統基礎工具安裝 (Git/Curl)"
    echo -e " 2) 安裝 Nginx 伺服器"
    echo -e " 3) 安裝 PHP 8.3 & Composer"
    echo -e " 4) 安裝 Node.js v22 & pnpm"
    echo -e " 5) 安裝 MySQL Server"
    echo -e " 6) 設定 MySQL Root 密碼 (A123456a)"
    echo -e " 7) 📂 建立新資料庫 (Create DB)"
    echo -e " 8) 👤 建立使用者並授權 (Create User)"
    echo -e "------------------------------------------"
    echo -e " i) 🚀 一鍵安裝環境全餐 (1 到 6)"
    echo -e " q) 離開選單"
    echo -e "${GREEN}==========================================${NC}"
    echo -n "請選擇指令: "
}

while true; do
    show_menu
    read opt
    case $opt in
        1) fn_1_system_base; read -p "按 Enter 繼續..." ;;
        2) fn_2_install_nginx; read -p "按 Enter 繼續..." ;;
        3) fn_3_install_php; read -p "按 Enter 繼續..." ;;
        4) fn_4_install_node; read -p "按 Enter 繼續..." ;;
        5) fn_5_install_mysql; read -p "按 Enter 繼續..." ;;
        6) fn_6_mysql_root_setup; read -p "按 Enter 繼續..." ;;
        7) fn_7_mysql_create_db; read -p "按 Enter 繼續..." ;;
        8) fn_8_mysql_add_user; read -p "按 Enter 繼續..." ;;
        i) 
            fn_1_system_base
            fn_2_install_nginx
            fn_3_install_php
            fn_4_install_node
            fn_5_install_mysql
            fn_6_mysql_root_setup
            echo -e "${GREEN}🚀 核心環境安裝完成！${NC}"
            read -p "按 Enter 繼續..."
            ;;
        q) exit 0 ;;
        *) echo "無效選項"; sleep 1 ;;
    esac
done
