# MightyScroll — macOS Mighty Mouse 捲動工具

讓 Mighty Mouse 的小滾球在現代 Mac 上更順手。

[English](README.md) · **繁體中文**

MightyScroll 是免費開源的 macOS 選單列工具，為 Apple Mighty Mouse 提供獨立的滑鼠捲動方向、捲動加速與慣性設定，不影響觸控板原本的捲動方式。以 A1197 無線 Mighty Mouse 開發與實機測試。

由 **MAKOTO LAB** 獨立開發。

<p>
  <a href="https://github.com/lancer1234/MightyScroll/releases/download/v0.4.1/MightyScroll-0.4.1-universal.dmg"><img alt="Download MightyScroll 0.4.1 DMG for macOS" src="https://img.shields.io/badge/Download-v0.4.1%20DMG-2ea44f?style=for-the-badge&logo=github&logoColor=white"></a>
  <a href="https://buymeacoffee.com/MakotoLab"><img alt="Support MAKOTO LAB on Buy Me a Coffee" src="https://img.shields.io/badge/Support-MAKOTO%20LAB-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000"></a>
  <a href="https://www.instagram.com/d.wang___/"><img alt="Instagram @d.wang___" src="https://img.shields.io/badge/Instagram-%40d.wang______-E4405F?style=for-the-badge&logo=instagram&logoColor=white"></a>
</p>

## 功能

- 滑鼠與觸控板分開設定捲動方向。
- 上下、左右可獨立調整。
- 慢速捲動精準定位，快速連滾時增加捲動距離。
- 快速連滾之間保持流暢，停手後自然減速。
- 自訂捲動行數、加速上限與慣性強度。
- 滑鼠重新連線後自動恢復。
- 登入時啟動，原生介面支援明暗模式。

## 開始使用

需要 **macOS 13.5 以上**。DMG 包含 Apple silicon 與 Intel 版本；Intel 硬體尚未實機測試。安裝不需要 Xcode。

1. [下載 DMG](https://github.com/lancer1234/MightyScroll/releases/download/v0.4.1/MightyScroll-0.4.1-universal.dmg)，開啟後將 **MightyScroll** 拖進 **Applications**。更新時請先結束原本的程式。
2. 從「應用程式」開啟。此版本尚未經 Apple 公證；若 macOS 阻擋，確認來自此專案後，可依 [Apple 的開啟說明](https://support.apple.com/en-us/102445)，到「隱私權與安全性」查看「強制打開」。
3. 在「系統設定 → 隱私權與安全性」授權「輔助使用」。原始滾輪輸入可能也需要「輸入監控」。
4. 在 macOS 保留慣用的觸控板方向，透過 MightyScroll 選單列圖示調整滑鼠。

可在程式設定中切換「登入時啟動」。如需使用 Xcode 自行建置，請見[開發筆記](docs/DEVELOPMENT.md)。

## 常見問題

**可以只反轉滑鼠方向，不改變觸控板嗎？**

可以。在 macOS 保留慣用的自然捲動設定，再用 MightyScroll 調整滑鼠方向。

**支援 Magic Mouse 嗎？**

目前尚未驗證 Magic Mouse 相容性，已測試的裝置是 A1197 無線 Mighty Mouse。

**MightyScroll 是免費開源的嗎？**

是，原始碼採用 MIT 授權，贊助完全自願。

## 相容性與隱私

以 **A1197 無線 Mighty Mouse** 開發與實機測試，已確認藍牙重連後能恢復使用。其他滑鼠與 App 尚未全面測試，目前未提供中鍵或側邊擠壓按鍵重新配置。

沒有網路請求、遙測或鍵盤監聽，設定只儲存在你的 Mac。

建置細節、相容性說明與問題排查請見[開發筆記](docs/DEVELOPMENT.md)。

## 問題回報

<p>
  <a href="https://github.com/lancer1234/MightyScroll/issues"><img alt="Report a MightyScroll bug" src="https://img.shields.io/badge/GitHub-Report%20a%20Bug-d73a49?style=for-the-badge&logo=github&logoColor=white"></a>
</p>

遇到問題時，歡迎[提出 Issue](https://github.com/lancer1234/MightyScroll/issues)，附上 macOS 版本、滑鼠型號、測試 App 與重現步驟。

## 支持 MAKOTO LAB

MightyScroll 是我利用自己的時間開發的專案。如果它讓你的滑鼠更好用，歡迎請我喝杯咖啡，支持後續開發與添購測試硬體。

<p>
  <a href="https://buymeacoffee.com/MakotoLab"><img alt="Support MAKOTO LAB on Buy Me a Coffee" src="https://img.shields.io/badge/Support-MAKOTO%20LAB-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000"></a>
</p>

贊助完全自願，不代表購買功能或優先支援。

## 關於 MAKOTO LAB

MAKOTO LAB 是獨立的實驗性軟硬體工作室，探索特殊、已停產與新興的運算平台。我透過客製軟體與新的互動方式，探索這些裝置在今天還能做些什麼。

也歡迎看看 [Makoto Glass](https://github.com/lancer1234/MakotoGlass-Beta)，將 iPhone 整合帶到 Google Glass 的另一個專案。

<p>
  <a href="https://www.instagram.com/d.wang___/"><img alt="Instagram @d.wang___" src="https://img.shields.io/badge/Instagram-%40d.wang______-E4405F?style=for-the-badge&logo=instagram&logoColor=white"></a>
  <a href="https://buymeacoffee.com/MakotoLab"><img alt="Support MAKOTO LAB on Buy Me a Coffee" src="https://img.shields.io/badge/Support-MAKOTO%20LAB-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000"></a>
</p>

## 授權

<p>
  <a href="LICENSE"><img alt="View MIT License" src="https://img.shields.io/badge/License-MIT-555?style=for-the-badge"></a>
</p>

採用 [MIT 授權](LICENSE)。MightyScroll 是獨立專案，與 Apple 無隸屬關係。
