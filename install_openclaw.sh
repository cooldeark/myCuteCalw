#!/bin/bash

# --- [顏色與路徑設定] ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
CLAW_PATH="/opt/lobster_tank"
REAL_USER=${SUDO_USER:-$(whoami)}
USER_ID_NUM=$(id -u $REAL_USER)

get_bus_env() {
    echo "XDG_RUNTIME_DIR=/run/user/$USER_ID_NUM DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID_NUM/bus"
}

check_env() {
    if [ ! -d "$CLAW_PATH" ]; then
        echo -e "${RED}❌ 錯誤：找不到目錄 $CLAW_PATH。${NC}"
        return 1
    fi
    cd "$CLAW_PATH" || return 1
}

run_step() {
    echo -e "${YELLOW}>>> 正在執行：$2 ...${NC}"
    $1 
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ [成功]：$2${NC}"
        return 0
    else
        echo -e "${RED}❌ [失敗]：$2${NC}"
        return 1
    fi
}

# --- [基礎建置功能] ---
fn_1_system_base() { sudo apt update && sudo apt install -y curl git build-essential python3-dev libffi-dev; }
fn_2_env_tools() { curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs && sudo npm install -g pm2 pnpm; }
fn_3_git_clone() { [ -d "$CLAW_PATH/.git" ] && (cd "$CLAW_PATH" && sudo -u $REAL_USER git pull) || (sudo mkdir -p "$CLAW_PATH" && sudo chown -R $REAL_USER:$REAL_USER "$CLAW_PATH" && sudo -u $REAL_USER git clone https://github.com/openclaw/openclaw.git "$CLAW_PATH"); }
fn_4_pnpm_build() { check_env || return 1; sudo chown -R $REAL_USER:$REAL_USER "$CLAW_PATH"; sudo -u $REAL_USER rm -rf dist node_modules; sudo -u $REAL_USER pnpm install && sudo -u $REAL_USER pnpm run build && sudo -u $REAL_USER pnpm ui:build; }
fn_5_linger() { sudo loginctl enable-linger $REAL_USER; }

# --- [6 配置同步：模型字串精準版] ---
fn_6_config_sync() {
    check_env || return 1
    [ ! -f "dist/index.js" ] && echo -e "${RED}錯誤：未編譯。${NC}" && return 1

    echo -e "${YELLOW}正在執行基地降溫與檔案鎖定清理...${NC}"
    sudo -u $REAL_USER env $(get_bus_env) systemctl --user stop openclaw-gateway > /dev/null 2>&1
    pgrep -f "node.*openclaw" | grep -v $$ | xargs sudo kill -9 > /dev/null 2>&1
    sudo rm -f /home/$REAL_USER/.openclaw/*.lock > /dev/null 2>&1
    sleep 2
    stty sane

    read -e -p "1. Gemini API Key: " USER_GEMINI
    read -e -p "2. Telegram Bot Token: " USER_TOKEN
    read -e -p "3. Telegram User ID: " USER_ID
    # 🔥 修正：使用龍蝦 3.14 認得的精確模型名稱
    read -e -p "4. 模型選擇 [1: 2.0-flash (推薦), 2: 1.5-flash]: " MODEL_CHOICE
    read -e -p "5. 檢查間隔 [預設 12h，可節省免費配額]: " USER_INTERVAL
    
    SELECTED_MODEL="google/gemini-2.0-flash"
    [ "$MODEL_CHOICE" == "2" ] && SELECTED_MODEL="google/gemini-1.5-flash"
    USER_INTERVAL=${USER_INTERVAL:-12h}

    sudo -u $REAL_USER cat <<EOT > "$CLAW_PATH/.env"
GEMINI_API_KEY=$USER_GEMINI
TELEGRAM_BOT_TOKEN=$USER_TOKEN
ALLOWED_TELEGRAM_USER_IDS=$USER_ID
OPENCLAW__AGENTS__DEFAULTS__HEARTBEAT__CADENCE=$USER_INTERVAL
NODE_ENV=production
NODE_OPTIONS="--dns-result-order=ipv4first"
EOT

    echo -e "${YELLOW}正在同步核心大腦設定...${NC}"
    sudo -u $REAL_USER node dist/index.js agents create --name main 2>/dev/null
    sudo -u $REAL_USER node dist/index.js config set gateway.mode local
    sudo -u $REAL_USER node dist/index.js config set agents.defaults.model "$SELECTED_MODEL"
    sudo -u $REAL_USER node dist/index.js config set channels.telegram.enabled true
    sudo -u $REAL_USER node dist/index.js channels set telegram --allowFrom "[$USER_ID]" 2>/dev/null || sudo -u $REAL_USER node dist/index.js config set channels.telegram.allowFrom "[$USER_ID]"

    NODE_BIN=$(which node)
    SERVICE_FILE="/home/$REAL_USER/.config/systemd/user/openclaw-gateway.service"
    mkdir -p $(dirname $SERVICE_FILE)
    sudo -u $REAL_USER cat <<EOT > $SERVICE_FILE
[Unit]
Description=OpenClaw Manager V3.5.8
After=network.target
[Service]
Type=simple
WorkingDirectory=$CLAW_PATH
ExecStart=$NODE_BIN $CLAW_PATH/dist/index.js gateway
Restart=always
EnvironmentFile=$CLAW_PATH/.env
[Install]
WantedBy=default.target
EOT
    sudo -u $REAL_USER env $(get_bus_env) systemctl --user daemon-reload
    fn_restart
}

# --- [🎖️ 兵團指揮官管理區：五大功能] ---
fn_census() { check_env && sudo -u $REAL_USER node dist/index.js agents list 2>/dev/null | grep "^- " | sed 's/- /🦞 /' || echo "無活躍特務。"; }
fn_add_agent() { check_env || return; read -e -p "新特務名稱: " NAME; [ -n "$NAME" ] && sudo -u $REAL_USER node dist/index.js agents create --name "$NAME"; }
fn_del_agent() { check_env || return; fn_census; read -e -p "裁撤名稱: " NAME; [[ "$NAME" != "main" && -d "/home/$REAL_USER/.openclaw/agents/$NAME" ]] && sudo -u $REAL_USER rm -rf "/home/$REAL_USER/.openclaw/agents/$NAME" || echo "取消。"; }
fn_toggle_agent() { local m=$1; check_env || return; fn_census; read -e -p "代號: " N; [ -z "$N" ] && return; sudo -u $REAL_USER node dist/index.js config set agents."$N".enabled $m; echo "已更新，按 [r] 重啟。"; }

# --- [🕹️ 運維控制與診斷] ---
fn_stop() { echo -e "${YELLOW}🛑 強制停止龍蝦進程...${NC}"; sudo -u $REAL_USER env $(get_bus_env) systemctl --user stop openclaw-gateway > /dev/null 2>&1; pgrep -f "node.*openclaw" | grep -v $$ | xargs sudo kill -9 > /dev/null 2>&1; echo -e "${GREEN}✅ 已冷卻。${NC}"; }
fn_start() { check_env && sudo -u $REAL_USER env $(get_bus_env) systemctl --user start openclaw-gateway; }
fn_restart() { fn_stop; sleep 1; fn_start; echo -e "${GREEN}✅ 重新啟動成功。${NC}"; }
fn_status() { sudo -u $REAL_USER env $(get_bus_env) systemctl --user status openclaw-gateway; }
fn_logs() { echo -e "${YELLOW}正在進入過濾日誌模式... (按 Ctrl + C 結束)${NC}"; sudo -u $REAL_USER env $(get_bus_env) journalctl --user -u openclaw-gateway -f | grep -vE "bonjour|probing|restarting advertiser|Can't probe"; }

# --- [主選單界面] ---
show_menu() {
    clear; stty sane
    echo -e "${GREEN}==========================================${NC}"
    echo -e "    🦞 OpenClaw Manager V3.5.8"
    echo -e "${GREEN}==========================================${NC}"
    echo -e " 1) 系統基礎工具安裝"
    echo -e " 2) Node.js 與環境建置"
    echo -e " 3) 專案代碼下載/更新"
    echo -e " 4) 專案編譯與建置"
    echo -e " 5) 系統持久化設定"
    echo -e " 6) 配置同步與自動徵召"
    echo -e "------------------------------------------"
    echo -e "${YELLOW}🎖️ 兵團精確指揮：${NC}"
    echo -e " c) 龍蝦兵團普查 (點名)"
    echo -e " a) 招募新龍蝦特務 (Add)"
    echo -e " x) 裁撤舊龍蝦特務 (Delete)"
    echo -e " e) 啟用特定特務 (Enable)"
    echo -e " p) 暫停特定特務 (Pause)"
    echo -e " n) 網路連線診斷 (Network)"
    echo -e " d) 清理過大日誌 (Clear)"
    echo -e "------------------------------------------"
    echo -e "${YELLOW}🕹️ 運維控制中心：${NC}"
    echo -e " s) 啟動龍蝦兵團"
    echo -e " t) 強制停止清場"
    echo -e " r) 重新啟動兵團"
    echo -e " k) 狀態檢查 (Status)"
    echo -e " l) 查看即時日誌 (Logs)"
    echo -e "------------------------------------------"
    echo -e " i) 一鍵全自動安裝 (1 -> 6)"
    echo -e " q) 離開選單"
    echo -e "${GREEN}==========================================${NC}"
    echo -n "指令選擇: "
}

while true; do
    show_menu; read opt
    case $opt in
        1) run_step fn_1_system_base "1"; read -p "按 [Enter] 返回..." ;;
        2) run_step fn_2_env_tools "2"; read -p "按 [Enter] 返回..." ;;
        3) run_step fn_3_git_clone "3"; read -p "按 [Enter] 返回..." ;;
        4) run_step fn_4_pnpm_build "4"; read -p "按 [Enter] 返回..." ;;
        5) run_step fn_5_linger "5"; read -p "按 [Enter] 返回..." ;;
        6) run_step fn_6_config_sync "6"; read -p "按 [Enter] 返回..." ;;
        c) fn_census; read -p "按 [Enter] 返回..." ;;
        a) fn_add_agent; read -p "按 [Enter] 返回..." ;;
        x) fn_del_agent; read -p "按 [Enter] 返回..." ;;
        e) fn_toggle_agent "true"; read -p "按 [Enter] 返回..." ;;
        p) fn_toggle_agent "false"; read -p "按 [Enter] 返回..." ;;
        n) ping -c 1 api.telegram.org > /dev/null 2>&1 && echo "DNS 正常" || echo "DNS 失敗"; read -p "按 [Enter] 返回..." ;;
        d) sudo rm -rf /tmp/openclaw/*.log; read -p "日誌已清..." ;;
        s) fn_start; sleep 1 ;;
        t) fn_stop; sleep 1 ;;
        r) fn_restart; sleep 1 ;;
        k) fn_status; read -p "按 [Enter] 返回..." ;;
        l) fn_logs ;;
        i) run_step fn_1_system_base "1" || break; run_step fn_2_env_tools "2" || break; run_step fn_3_git_clone "3" || break; run_step fn_4_pnpm_build "4" || break; run_step fn_5_linger "5" || break; run_step fn_6_config_sync "6" || break; echo -e "${GREEN}⭐ 部署成功！${NC}"; read -p "按 [Enter] 返回..." ;;
        q) exit 0 ;;
    esac
done
