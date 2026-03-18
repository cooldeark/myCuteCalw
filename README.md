# 🦞 OpenClaw Manager V3.9.0 (GAPOON Edition)

![OpenClaw Version](https://img.shields.io/badge/OpenClaw-2026.3.14_(1561c6a)-green)
![Node Version](https://img.shields.io/badge/Node-v22.x-blue)
![Status](https://img.shields.io/badge/Status-Stable_v3.9.0-orange)

這是專為 **OpenClaw 2026.3.14 (1561c6a)** 打造的運維管理腳本。旨在解決 2026 年環境下遇到的 TypeScript 編譯衝突與配置校驗 Bug。

---

## 🛠️ V3.9.0 核心修復說明

- **強制編譯修復 (TS2344)**：自動於 `src/config/zod-schema.core.ts` 注入 `// @ts-nocheck`，解決官方版本 `thinkingFormat` 類型不匹配導致的編譯中斷。
- **解鎖啟動攔截**：自動注入 `gateway.mode: local`，修正清空配置目錄後出現的 `Gateway start blocked` 報錯。
- **心跳間隔同步**：完整支援 `.env` 環境變數注入，確保 `HEARTBEAT_CADENCE` 定時任務穩定運作。
- **絕對垂直選單**：優化選單排版，所有操作選項（s, t, r, k, l, d）採垂直對位排列，提升監控體驗。

---

## 🚀 部署與使用

1. **環境初始化**：
   執行腳本選單中的 **`i` (一鍵安裝全餐)**，系統將自動完成工具安裝、代碼下載、**原始碼手術修復**及編譯建置。
   
2. **啟動/重啟**：
   - 啟動兵團：按 **`s`**
   - 重新啟動：按 **`r`** (修改 JSON 後必執行)
   - 查看日誌：按 **`l`**

---

## 📡 Telegram 遠端指令 (即時更新)

部署後無需手動編輯伺服器檔案，直接於 Telegram 對機器人發送以下指令：

### 1. 更新大腦/持股背景
指令語法：`/agent main instruction [您的專長指令]`

> **實戰範例 (複製後發送)：**
> `/agent main instruction 你是 GAPOON，首席特務。說話精煉、毒舌且幽默。背景：James 持有 25 張華邦電 (均價 114) 與台積電。任務：主動搜尋 2026 年最新財報、法人評等與 EPS。分析時請以 James 的持股損益與風險為核心給予赤裸建議。`

### 2. 運維輔助語法
- **查詢目前指令**：`/agent main instruction?`
- **調整理智溫度**：`/agent main config.temperature 0.1` (0.1 最冷靜, 0.7 較有創意)
- **聯網工具檢查**：`/agent main tools?`

---

## 🏥 手動配置 JSON 參考

若需手動修改 `~/.openclaw/openclaw.json`，請務必遵守 1561c6a 規定的 `profiles` 結構：

```json
{
  "agents": {
    "profiles": {
      "main": {
        "enabled": true,
        "model": "google/gemini-2.5-flash",
        "instruction": "[您的持股背景與專長]",
        "tools": ["google_search_retrieval"]
      }
    }
  }
}
