#!/bin/bash

# --- [顏色與基礎路徑] ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
CLAW_PATH="/opt/lobster_tank"
REAL_USER=${SUDO_USER:-$(whoami)}
USER_ID_NUM=$(id -u $REAL_USER)

get_bus_env() { echo "XDG_RUNTIME_DIR=/run/user/$USER_ID_NUM DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID_NUM/bus"; }
check_env() { [ ! -d "$CLAW_PATH" ] && echo -e "${RED}❌ 錯誤：找不到目錄 $CLAW_PATH。${NC}" && return 1; cd "$CLAW_PATH" || return 1; }

# --- [1-5 基礎功能] ---
fn_1_system_base() { sudo apt update && sudo apt install -y curl git build-essential jq; }
fn_2_env_tools() { curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs && sudo npm install -g pnpm; }
fn_3_git_clone() { [ -d "$CLAW_PATH/.git" ] && (cd "$CLAW_PATH" && sudo -u $REAL_USER git pull) || (sudo mkdir -p "$CLAW_PATH" && sudo chown -R $REAL_USER:$REAL_USER "$CLAW_PATH" && sudo -u $REAL_USER git clone https://github.com/openclaw/openclaw.git "$CLAW_PATH"); }
fn_4_pnpm_build() { check_env || return 1; sudo -u $REAL_USER pnpm install && sudo -u $REAL_USER pnpm run build; }
fn_5_linger() { sudo loginctl enable-linger $REAL_USER; }

# --- [m) 2026 診斷模式] ---
fn_list_models() {
    read -e -p "請貼上 API Key 進行診斷: " TEST_KEY
    echo -e "${YELLOW}正在請求 2026 模型庫存...${NC}"
    RESULT=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=$TEST_KEY")
    if echo "$RESULT" | grep -q "error"; then
        echo -e "${RED}錯誤：${NC}"; echo "$RESULT" | jq .error.message
    else
        echo -e "${GREEN}✅ 可用模型字串：${NC}"
        echo "$RESULT" | jq -r '.models[] | select(.supportedGenerationMethods[] | contains("generateContent")) | .name' | sed 's/models\///'
    fi
    read -p "按 [Enter] 返回..."
}

# --- [6 配置同步：2026.3.14 修正版] ---
fn_6_config_sync() {
    check_env || return 1
    echo -e "${YELLOW}🔥 基地淨化：執行 2026.3.14 規格化清場...${NC}"
    sudo -u $REAL_USER env $(get_bus_env) systemctl --user stop openclaw-gateway > /dev/null 2>&1
    pgrep -f "node.*openclaw" | grep -v $$ | xargs sudo kill -9 > /dev/null 2>&1
    sudo rm -rf /home/$REAL_USER/.openclaw/sessions/*
    
    read -e -p "1. Gemini API Key: " USER_GEMINI
    read -e -p "2. Telegram Bot Token: " USER_TOKEN
    read -e -p "3. Telegram User ID: " USER_ID
    echo -e "${YELLOW}請輸入模型 (建議: gemini-2.5-flash):${NC}"
    read -e -p "4. 模型字串: " SELECTED_MODEL
    read -e -p "5. 檢查間隔 [預設 12h]: " USER_INTERVAL
    echo -e "${YELLOW}請輸入特務專長 (System Instruction):${NC}"
    read -e -p "6. 專長描述: " USER_SYS

    USER_INTERVAL=${USER_INTERVAL:-12h}
    [[ $USER_INTERVAL =~ ^[0-9]+$ ]] && USER_INTERVAL="${USER_INTERVAL}h"
    USER_SYS=${USER_SYS:-"你是一個專業的 AI 助手。"}

    # 寫入 .env
    sudo -u $REAL_USER cat <<EOT > "$CLAW_PATH/.env"
GEMINI_API_KEY=$USER_GEMINI
TELEGRAM_BOT_TOKEN=$USER_TOKEN
ALLOWED_TELEGRAM_USER_IDS=$USER_ID
OPENCLAW__AGENTS__DEFAULTS__HEARTBEAT__CADENCE=$USER_INTERVAL
OPENCLAW__GATEWAY__DISCOVERY__ENABLED=false
NODE_ENV=production
NODE_OPTIONS="--dns-result-order=ipv4first"
EOT

    echo -e "${YELLOW}🛡️ 執行 2026.3.14 專用 update 指令注入強化組件...${NC}"
    # 1. 先確保特務存在
    sudo -u $REAL_USER node dist/index.js agents create --name main 2>/dev/null
    
    # 🔥 核心修正：使用 agents update 而非 config set
    # 這是為了解決 Unrecognized key: "main" 的問題
    sudo -u $REAL_USER node dist/index.js agents update main \
        --model "google/$SELECTED_MODEL" \
        --system-instruction "$USER_SYS" \
        --tools "['google_search_retrieval']" \
        --temperature 0.1 \
        --max-output-tokens 4096 \
        --enabled true

    # 2. 頻道設定 (這部分依然使用 config set，因為它是全局的)
    sudo -u $REAL_USER node dist/index.js config set channels.telegram.enabled true
    sudo -u $REAL_USER node dist/index.js config set channels.telegram.allowFrom "[$USER_ID]"
    
    fn_restart
}

# --- [運維控制區：絕對垂直對齊] ---
fn_stop() { sudo -u $REAL_USER env $(get_bus_env) systemctl --user stop openclaw-gateway > /dev/null 2>&1; pgrep -f "node.*openclaw" | grep -v $$ | xargs sudo kill -9 > /dev/null 2>&1; }
fn_start() { check_env && sudo -u $REAL_USER env $(get_bus_env) systemctl --user start openclaw-gateway; }
fn_restart() { fn_stop; sleep 1; fn_start; echo -e "${GREEN}✅ GAPOON 修正版已啟動。${NC}"; }
fn_status() { sudo -u $REAL_USER env $(get_bus_env) systemctl --user status openclaw-gateway; }
fn_logs() { sudo -u $REAL_USER env $(get_bus_env) journalctl --user -u openclaw-gateway -f | grep -vE "bonjour|probing"; }

show_menu() {
    clear; stty sane
    echo -e "${GREEN}==========================================${NC}"
    echo -e "    🦞 OpenClaw Manager V3.7.2"
    echo -e "${GREEN}==========================================${NC}"
    echo -e " 1) 系統工具安裝"
    echo -e " 2) Node 環境建置"
    echo -e " 3) 代碼更新"
    echo -e " 4) 編譯建置"
    echo -e " 5) 持久化設定"
    echo -e " 6) 🚀 配置同步 (修正 2026.3.14 報錯)"
    echo -e "------------------------------------------"
    echo -e "${YELLOW}🎖️  兵團指揮區：${NC}"
    echo -e " c) 兵團普查 (Census)"
    echo -e " a) 招募新特務 (Add)"
    echo -e " e) [啟用] 特務 (Enable)"
    echo -e " p) [暫停] 特務 (Pause)"
    echo -e " m) 🔍 診斷可用模型 (必查)"
    echo -e "------------------------------------------"
    echo -e "${YELLOW}🕹️  運維控制中心：${NC}"
    echo -e " s) 啟動兵團 (Start)"
    echo -e " t) 停止清場 (Stop)"
    echo -e " r) 重新啟動 (Restart)"
    echo -e " k) 狀態檢查 (Status)"
    echo -e " l) 查看即時日誌 (Logs)"
    echo -e " d) 清理日誌 (Clear)"
    echo -e "------------------------------------------"
    echo -e " i) 一鍵安裝全餐"
    echo -p " q) 離開選單"
    echo -e "${GREEN}==========================================${NC}"
    echo -n "指令選擇: "
}

while true; do
    show_menu; read opt
    case $opt in
        [1-5]) $opt; read -p "返回..." ;;
        6) fn_6_config_sync; read -p "返回..." ;;
        c) check_env && sudo -u $REAL_USER node dist/index.js agents list; read -p "返回..." ;;
        a) check_env && read -e -p "代號: " N && [ -n "$N" ] && sudo -u $REAL_USER node dist/index.js agents create --name "$N"; read -p "返回..." ;;
        e) check_env && read -e -p "代號: " N && sudo -u $REAL_USER node dist/index.js agents update "$N" --enabled true; read -p "返回..." ;;
        p) check_env && read -e -p "代號: " N && sudo -u $REAL_USER node dist/index.js agents update "$N" --enabled false; read -p "返回..." ;;
        m) fn_list_models ;;
        s) fn_start; sleep 1 ;;
        t) fn_stop; sleep 1 ;;
        r) fn_restart; sleep 1 ;;
        k) fn_status; read -p "返回..." ;;
        l) fn_logs ;;
        d) sudo rm -rf /tmp/openclaw/*.log; read -p "已清..." ;;
        i) fn_1_system_base; fn_2_env_tools; fn_3_git_clone; fn_4_pnpm_build; fn_5_linger; fn_6_config_sync; read -p "返回..." ;;
        q) exit 0 ;;
    esac
done
