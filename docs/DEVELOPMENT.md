# 開發與相容性說明

這份文件整理建置、裝置辨識、測試與問題排查的細節。一般使用方式請見 [README](../README.zh-TW.md)。

## 建置

```sh
xcodebuild -project MightyScroll.xcodeproj \
  -scheme MightyScroll -configuration Release \
  -derivedDataPath .build build
```

輸出位於 `.build/Build/Products/Release/MightyScroll.app`。專案預設使用本機 ad-hoc 簽章。

## 打包 DMG

```sh
./scripts/create-dmg.sh
```

產生 Apple silicon／Intel Universal App、可拖進 Applications 的 DMG，以及 SHA-256 校驗檔，輸出到 `build/`。可傳入另一個輸出資料夾。預設仍為 ad-hoc 簽章，未經 Apple 公證；Intel 硬體尚未實機測試。

## 裝置辨識與相容性

以 A1197 無線 Mighty Mouse 作為主要實機開發裝置，已在開發者的 Mac 確認捲動與重新連線後自動恢復；其他滑鼠與所有 macOS 版本尚未全面測試。部分 Mighty Mouse 事件會被回報為連續捲動，因此不能只以連續性區分滑鼠與觸控板。

MightyScroll 優先讀取事件的硬體來源與裝置屬性。HID 用戶端尚未發現重連裝置時，也會查詢 IORegistry。已辨識的觸控板保持原樣；無法辨識來源的連續捲動則保留系統行為。

快速連滾優先以實體滾輪增量判斷；無法取得原始輸入時，退回事件頻率估計。基本行數以 macOS 收到的一個非零捲動事件為單位，不等於一次完整的手指動作。快速捲動以 120 Hz 排程輸出，實際流暢度依顯示器和目標 App 而異。

部分硬體辨識使用動態載入的 macOS 非公開介面，可能受未來系統更新影響。本專案適合本機建置使用；預設建置未經 Developer ID 公證。Apple 的名稱與商標屬於 Apple，本專案與 Apple 無隸屬關係。

目前會處理符合辨識條件的滑鼠，尚未提供指定單一裝置的設定，也未提供中鍵或側邊擠壓按鍵重新配置。測試時請先暫停其他捲動修改工具。

## 問題回報

展開「辨識資訊」，比較小滾球與觸控板的顯示結果。回報時請附上 macOS 版本、滑鼠型號、測試 App，以及問題是否發生於重新連線或睡眠喚醒後。

- 顯示「未辨識裝置」：來源尚未成功辨識。
- 顯示已套用設定但沒有作用：可能是目標 App 的特殊輸入介面或其他工具的干擾。
- 重建或替換 App 後授權失效：從輔助使用中移除舊項目，重新加入新 App。

## 測試

```sh
./test.sh
```

測試涵蓋方向轉換、觸控板保護、基本步進、慢速／快速輸入、反向與停頓重置、動量累積與衰減、不同更新頻率的一致性，以及輸出事件跟隨當下游標位置。A1197 的藍牙斷線重連已在開發者的 Mac 實機確認；其他裝置與各 App 的相容性仍需另外驗證。

## 隱私

沒有網路請求、遙測或鍵盤監聽。只處理滑鼠滾輪增量與捲動事件；設定儲存在本機。辨識資訊不寫入事件紀錄。

## 參考

- [Apple Core Graphics](https://developer.apple.com/documentation/coregraphics/cgevent)：事件攔截與捲動資料。
- [Scroll Reverser](https://github.com/pilotmoon/Scroll-Reverser)：捲動欄位的連動行為。
- [LinearMouse](https://github.com/linearmouse/linearmouse)：HID 事件來源與裝置辨識。
- [Emil Kowalski — apple-design](https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md)：介面設計參考。

