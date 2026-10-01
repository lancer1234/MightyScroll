# MightyScroll

讓 Mighty Mouse 的小滾球在現代 macOS 上更順手。

MightyScroll 是以 SwiftUI 與 AppKit 製作的選單列工具，讓滑鼠和觸控板使用不同的捲動方向，並提供慢速定位、快速連滾加速與慣性捲動。

## 功能

- 滑鼠與觸控板分開處理捲動方向。
- 上下、左右獨立設定方向與基本行數，預設每次 2 行。
- 慢速捲動直接回應；快速連滾增加每次距離，加速上限預設 3 倍。
- 快速捲動的動量持續累積，停手後自然衰減，慣性強度預設 1.8 倍。
- 反向捲動、切回觸控板或暫停時，中止原本的動量。
- 慣性期間可自由移動游標。
- 原生登入項目、設定自動儲存，以及明暗模式。
- 裝置連線／斷線時更新辨識資料、重建監聽；喚醒時重新開啟原始輸入監聽。

## 建置與使用

需要 macOS 13.5 以上和支援 SwiftUI 的 Xcode。開啟 `MightyScroll.xcodeproj`，選擇 **MightyScroll → My Mac**，按 Run。專案預設使用本機 ad-hoc 簽章。

也可以從專案根目錄建置：

```sh
xcodebuild -project MightyScroll.xcodeproj \
  -scheme MightyScroll -configuration Release \
  -derivedDataPath .build build
```

將 `.build/Build/Products/Release/MightyScroll.app` 放進「應用程式」後開啟。

1. 授權「系統設定 → 隱私權與安全性 → 輔助使用」。原始滾輪輸入可能也需要「輸入監控」。
2. 在 macOS 保留觸控板慣用的「自然捲動」，用 MightyScroll 調整滑鼠方向。
3. 調整上下／左右基本行數、加速上限與慣性強度。

首次從 `/Applications` 開啟會註冊登入項目，可用「登入時啟動」開關關閉。若系統要求核准，點「確認登入項目…」。登入啟動時只在選單列執行。

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

## 授權

[MIT](LICENSE)
