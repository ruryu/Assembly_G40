; ============================================================
; graphics.inc
; 宣告 graphics.asm 中所有可被其他檔案呼叫的副程式 (PROTO)
; 讓 main.asm、logic.asm 能正確使用 INVOKE 呼叫它們
; ============================================================

; 檢查玩家輸入的單字 (current_word) 與正確答案 (correct_word)
; 每個字母會回傳顏色狀態：0=不在答案、1=字母在答案但位置錯、2=字母完全正確
CheckWord PROTO current_word: DWORD, correct_word: DWORD

; 顯示單一字元與對應的顏色
; color_bg：0=灰色（錯）、1=黃色（字對位置錯）、2=綠色（金色）（字母正確）
DisplayChar PROTO color_bg: BYTE, char: BYTE

; 初始化畫面：設定背景、顯示 Wordle 標題、畫出 6 列輸入框
SetDisplay PROTO

; 清除指定列（ypos 為第幾次猜測），用在輸入錯誤時重畫該列
ClearLine PROTO ypos: DWORD

; 顯示錯誤訊息（例如：不是五個字母、不在字典）
DisplayError PROTO

; 顯示「成功」畫面（YOU WIN）
Winner PROTO

; 顯示「失敗」畫面，並印出正確答案 correct_word
Loser PROTO correct_word: DWORD

; 顯示 Wordle ASCII 標題（上方大字）
Wordle PROTO

; 避免未宣告的 PROC 被外部呼叫
OPTION PROC:PRIVATE
