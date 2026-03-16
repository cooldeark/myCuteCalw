# 🦞 OpenClaw Manager V3.5.8 — 指揮官旗艦版

![Version](https://img.shields.io/badge/Version-V3.5.8-green.svg)
![Compatibility](https://img.shields.io/badge/OpenClaw-3.14%20fba394c-blue.svg)

本腳本是專為 **OpenClaw (v3.14+)** 打造的深度運維管理終端，整合了數日來的實戰除錯經驗，旨在解決雲端伺服器環境中常見的連線死鎖、API 配額崩潰及進程自殘等問題。

---

## 🎖️ 指揮官核心戰術功能

### 1. 兵團精確管理 (Agent Management)
* **`c` 普查 (Census)**：一鍵列出所有活躍特務，掌握兵力分配。
* **`a` 招募 (Add)**：動態新增龍蝦特務，不需動到原始碼。
* **`x` 裁撤 (Delete)**：安全移除多餘特務（自動保護 `main` 特務）。
* **`e/p` 啟動與暫停**：針對特定特務進行休眠或喚醒，精準控制 API 消耗。

### 2. 環境自動優化 (Environment Fixes)
* **IPv4 優先連線**：自動注入 `dns-result-order=ipv4first`，解決 AWS 等雲端環境 IPv6 導致的 `ETIMEDOUT`。
* **進程隔離保護**：精準的 `pgrep` 斬首邏輯，確保殺死卡死的 Node 程式時，管理腳本不會自殺 (Self-Killed)。
* **日誌雜訊過濾**：自動屏蔽 `Bonjour/mDNS` 在雲端環境噴出的無效廣播警告。

---

## 🚀 部署指南

### 快速安裝
1. 在您的主機上創建腳本：
   ```bash
   nano install_openclaw.sh
   ```
2. 貼入 **V3.5.8** 代碼並存檔。
3. 賦予執行權限並啟動：
   ```bash
   chmod +x install_openclaw.sh && ./install_openclaw.sh
   ```

---

## 🕹️ 控制台指令對照表

| 指令 | 名稱 | 功能描述 |
| :--- | :--- | :--- |
| **`6`** | **配置同步** | 核心功能。寫入 API Key、Token 並鎖定 2.0-flash 模型。 |
| **`i`** | **一鍵安裝** | 從系統工具、Node 環境到編譯與配置，全自動一條龍部署。 |
| **`c/a/x`** | **兵團管理** | 查閱、新增、刪除龍蝦特務。 |
| **`e/p`** | **特務開關** | 啟用或暫停特定 Agent（需按 `r` 重啟生效）。 |
| **`l`** | **實時日誌** | 進入「純淨模式」監看，自動過濾 Bonjour 雜訊。 |
| **`s/t/r`** | **運維控制** | 啟動、停止（清場）、重啟網關服務。 |
| **`n`** | **網路診斷** | 檢查伺服器到 Telegram API 的通訊是否有被防火牆阻斷。 |

---

## 🩺 緊急排障 (Troubleshooting)

### ⚠️ 遇到 CPU 100% 或 SSH 卡死
如果發現龍蝦進程失控瘋狂重試，請在選單外執行「斬首指令」：
```bash
# 強制殺死所有龍蝦，但保留管理腳本進程
pgrep -f "node.*openclaw" | grep -v $$ | xargs sudo kill -9 > /dev/null 2>&1

# 清理檔案鎖定（防止下次啟動顯示已在執行）
sudo rm -f /home/$USER/.openclaw/*.lock
```

### ⚠️ 遇到 "API rate limit reached"
這通常是因為連線不穩導致的連鎖重試，請執行以下步驟：
1. 按 **`t`** 停止服務，讓基地冷卻 **15 分鐘**。
2. 執行指令清除緩存：
   ```bash
   sudo rm -rf /home/ubuntu/.openclaw/sessions/*
   sudo rm -rf /home/ubuntu/.openclaw/cache/*
   ```
3. 按 **`6`** 重新同步，將 `Heartbeat Cadence` 設為 **`24h`** 或更高以節省配額。

---

## 📜 版本演進紀錄 (Changelog)

* **V3.5.8 (Current)**: 修正 1.5-flash 模型字串，鎖定 Gemini 2.0 Flash 穩定版。
* **V3.5.6**: 引入環境變數層級的 Bonjour 靜默戰術。
* **V3.5.4**: 修正 `Killed` 自殺邏輯，改用 `grep -v $$` PID 避讓。
* **V3.4.0**: 引入 Systemd 持久化與持久化日誌。

---

> 🦞 **指揮官語錄**：
> *"Greetings, Professor Falken. Shall we play a game of clean diffs?"*
