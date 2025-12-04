; graphics.asm - 負責畫面顯示與 UI 的所有副程式（Wordle 介面）

INCLUDE Irvine32.inc
INCLUDE colors.inc
INCLUDE logic.inc
INCLUDE graphics.inc
INCLUDE wordart.inc

.data

ending  BYTE "Sorry. The Word of the Day was: ",0    ; 輸了之後顯示正確答案前面的字串
error   BYTE "Please enter a five letter word in the dictionary",0 ; 輸入錯誤時的提示
empty   BYTE "_____",0                               ; 每一列一開始顯示的五個底線
why     BYTE "_________________________________________________",0 ; 拿來「蓋掉」整行用的長底線
start_box_h BYTE 15                                  ; 起始方框高度（目前沒特別用到）

.code

;---------------------------------------------------------
; CheckWord
; 功能：
;   檢查玩家輸入的單字 (current_word) 跟正確答案 (correct_word)，
;   對每一個字母判斷：
;     - 字母 + 位置都對       → color = 2
;     - 字母有在答案裡但位置錯 → color = 1
;     - 字母完全不在答案裡   → color = 0
;   然後呼叫 DisplayChar，把顏色與字母畫在畫面上。
;
; 參數：
;   current_word : DWORD  → 玩家輸入的 5 個字母字串位址
;   correct_word : DWORD  → 正確答案（word of the day）字串位址
;
; 暫存器角色：
;   esi → 指向玩家目前正在檢查的字母
;   edi → 指向正確答案目前正在檢查的字母
;   ecx → 迴圈計數（總共 5 個字母）
;   ebx → 當作顏色狀態：0 / 1 / 2
;---------------------------------------------------------
CheckWord PROC USES eax ecx esi edi, current_word: DWORD, correct_word: DWORD
    ; 一個字母一個字母檢查，共 5 個
    mov ecx, 5
    mov esi, current_word        ; esi 指向玩家輸入字串
    mov edi, correct_word        ; edi 指向正確答案字串

WordLoop:
        ; 取出目前玩家輸入的字母到 AL
        mov al, [esi]

        ;-------------------------------------------------
        ; 第一步：檢查「位置也一樣」的情況
        ;   CharInSamePos(玩家字母, 正確答案該位置字母)
        ;   如果回傳相等 → 表示這個位置完全正確
        ;-------------------------------------------------
        push [edi]               ; 正確答案當前位置字母
        push [esi]               ; 玩家輸入的當前字母
        call CharInSamePos
        jne NotCorrect           ; 若不相同 → 去判斷「只有字母有沒有在答案裡」

        ; 字母 & 位置都正確 → color = 2
        mov ebx, 2
        jmp Display

NotCorrect:
        ;-------------------------------------------------
        ; 第二步：位置錯誤的情況下，再檢查字母是否有在答案裡出現
        ;   CharInWord(玩家字母, 正確答案整個字串)
        ;-------------------------------------------------
        push correct_word        ; 傳入整個正確答案字串位址
        push [esi]               ; 傳入玩家當前字母
        call CharInWord
        jne Wrong                ; 若沒找到 → 完全錯誤（灰色）

        ; 字母有在答案裡，但位置錯 → color = 1
        mov ebx, 1
        jmp Display

Wrong:
        ; 字母完全不在答案裡 → color = 0
        mov ebx, 0

Display:
        ;-------------------------------------------------
        ; 這裡只負責把「顏色狀態」準備好，真的畫字交給 DisplayChar
        ;   ebx：0 / 1 / 2 代表不同顏色邏輯
        ;   eax：目前的字元（從 AL 來），這裡先壓到 stack 給 DisplayChar 用
        ;-------------------------------------------------
        push eax                 ; 暫存字元（DisplayChar 裡面會 pop 回來）

        ; 顯示單一字母（會依照 ebx 決定顏色，並把游標往右移）
        call DisplayChar

        ; 準備檢查下一個字母：玩家 & 答案指標都往後一個
        inc esi
        inc edi
        loop WordLoop

    ; 整列顯示完之後，稍微停一下，讓玩家看顏色變化
    mov eax, 500
    call Delay
    ret
CheckWord ENDP


;---------------------------------------------------------
; DisplayChar
; 功能：
;   根據 ebx 的顏色狀態決定要用哪種色彩顯示字元，
;   再把字元印出，最後把游標往右一格。
;
; 顏色約定（由 CheckWord 事先把 ebx 設好）：
;   ebx = 0 → 字母不在答案裡（灰底）
;   ebx = 1 → 字母有在答案裡但位置錯（黃底）
;   ebx = 2 → 字母與位置都對（綠底）
;
; 備註：
;   - PROC 形式參數 color_bg, char 在這裡實際沒有用到，
;     真正用的是：
;       ebx = 顏色狀態
;       eax = 字元（剛剛在 CheckWord 裡被 push，上來這裡會 pop）
;---------------------------------------------------------
DisplayChar PROC USES ebx eax, color_bg: BYTE, char: BYTE
    cmp ebx, 0
    je WrongColor          ; 0 → 完全錯

    cmp ebx, 1
    je InWordColor         ; 1 → 字有在答案裡，但位置錯

    ;---------------------------
    ; ebx = 2 → 字母 & 位置都正確
    ;---------------------------
    push eax
CorrectColor:
        mov eax, highlightCorrectPos   ; 顏色：位置正確
        call SetTextColor
        jmp PrintChar

WrongColor:
        ;---------------------------
        ; ebx = 0 → 完全錯誤的字母
        ;---------------------------
        mov eax, (tableBackground * 16) + fontColor ; 一般灰底 + 字色
        call SetTextColor
        jmp PrintChar

InWordColor:
        ;---------------------------
        ; ebx = 1 → 字在答案裡但位置不對
        ;---------------------------
        mov eax, highlightCorrectChar  ; 顏色：字對但位置錯
        call SetTextColor

PrintChar:
        ;---------------------------
        ; 把剛剛暫存的字元印出來，然後游標往右移一格
        ;---------------------------
        pop eax
        call WriteChar
        add dl, 1           ; x 座標 +1
        call GotoXY         ; 移動游標到新位置
        ret
DisplayChar ENDP


;---------------------------------------------------------
; SetDisplay
; 功能：
;   1. 設定整個遊戲畫面的背景顏色並清空螢幕
;   2. 在上方印出 Wordle 標題的 ASCII Art
;   3. 在中間畫出 6 列「_____」作為輸入方框
;---------------------------------------------------------
SetDisplay PROC USES eax edx
    ; 設定背景顏色 & 清除螢幕
    mov eax, backgroundColor * 17
    call SetTextColor
    call Clrscr

    ; 在 (5, 20) 印出 Wordle 標題 ASCII Art
    mov dh, 5
    mov dl, 20
    call GotoXY
    call Wordle

    ; 移到 (15, 50)，準備畫 6 列輸入方框
    mov dh, 15
    mov dl, 50
    call GotoXY
    mov ecx, 6              ; Wordle 總共可以猜 6 次 → 6 列

BoxLoop:
        ; 畫出一列 "_____"
        mov eax, tableBackground * 17
        call SetTextColor

        push edx
        mov edx, OFFSET empty    ; "_____"
        call WriteString
        mov edx, 0               ; 清暫存，不影響游標
        pop edx

        ; 換到下一列：y +1，x 回到 50
        add dh, 1
        mov dl, 50
        call GotoXY
        loop BoxLoop

    ; 畫完後，把游標放回第一列開頭，顏色設回表格底色
    mov dh, 15
    mov dl, 50
    call GotoXY
    mov eax, tableBackground * 17
    call SetTextColor
    ret
SetDisplay ENDP


;---------------------------------------------------------
; ClearLine
; 功能：
;   當玩家輸入錯誤（不是 5 個字母、或者不在字典裡），
;   清掉目前這一列的內容，重新畫回「_____」。
;
; 參數：
;   tries : DWORD → 第幾次嘗試（第 0 列、第 1 列...）
;
; 說明：
;   基準列是 dh = 15，
;   add dh, byte ptr [tries] 就是往下偏移「第幾列」。
;---------------------------------------------------------
ClearLine PROC USES eax edx, tries: DWORD
     ; 先用背景顏色在該列畫一條長底線，把之前打的字蓋掉
     mov eax, backgroundColor * 17
     call SetTextColor
     mov dl, 55
     mov dh, 15
     add dh, byte ptr [tries]   ; 根據第幾次嘗試決定是哪一列
     call GotoXY
     mov edx, OFFSET why        ; 一長串底線
     call WriteString

     ; 再把游標移回該列開頭，用表格顏色畫上新的「_____」
     mov dl, 50
     mov dh, 15
     add dh, byte ptr [tries]
     call GotoXY
     mov eax, tableBackground * 17
     call SetTextColor
     mov edx, OFFSET empty
     call WriteString
     ret
ClearLine ENDP


;---------------------------------------------------------
; DisplayError
; 功能：
;   在畫面的下方顯示錯誤訊息（例如：請輸入五個字母的合法單字），
;   停一秒讓玩家看清楚，之後再把錯誤訊息擦掉。
;---------------------------------------------------------
DisplayError PROC USES eax edx
    ; 顯示錯誤訊息
    mov dl, 25
    mov dh, 25
    call GotoXY
    mov eax, loserColor
    call SetTextColor
    mov edx, OFFSET error
    call WriteString

    ; 停 1000 ms
    mov eax, 1000
    call Delay

    ; 用背景色 + 長底線把錯誤訊息蓋掉
    mov dl, 25
    mov dh, 25
    call GotoXY
    mov eax, backgroundColor * 17
    call SetTextColor
    mov edx, OFFSET why
    call WriteString
    ret
DisplayError ENDP


;---------------------------------------------------------
; Winner
; 功能：
;   顯示「你贏了」畫面：
;     1. 清空螢幕
;     2. 設定勝利用的顏色
;     3. 在螢幕中央附近印出 waWinner ASCII Art
;---------------------------------------------------------
Winner PROC USES eax ebx ecx edx esi
    mov eax, backgroundColor * 17
    call SetTextColor
    call ClrScr

    mov eax, winnerColor
    call SetTextColor

    ; 從 (5, 20) 開始，一行一行印出 waWinner（共 8 行）
    mov bh, 5                   ; y 座標
    mov bl, 20                  ; x 座標
    mov ecx, 6
    mov esi, OFFSET waWinner

LoopWinner:
        mov dh, bh
        mov dl, bl
        call GotoXY
        mov edx, esi
        call WriteString
        inc bh                   ; 下一行
        add esi, waWinnerRowSize ; ASCII 的下一列
        loop LoopWinner
    ret
Winner ENDP


;---------------------------------------------------------
; Loser
; 功能：
;   顯示「你輸了」畫面：
;     1. 清空螢幕
;     2. 設定失敗用的顏色
;     3. 印出 waNomaidens ASCII Art
;     4. 在下方顯示正確答案字串。
;
; 參數：
;   correct_word : DWORD → 正確答案字串位址
;---------------------------------------------------------
Loser PROC USES eax ebx ecx edx esi, correct_word: DWORD
    mov eax, backgroundColor * 17
    call SetTextColor
    call ClrScr

    mov eax, loserColor
    call SetTextColor

    ; 從 (5, 20) 開始，一行一行印出 waNomaidens（共 6 行）
    mov bh, 5
    mov bl, 20
    mov ecx, 6
    mov esi, OFFSET waNomaidens

LoopLoser:
        mov dh, bh
        mov dl, bl
        call GotoXY
        mov edx, esi
        call WriteString
        inc bh
        add esi, waNomaidensRowSize
        loop LoopLoser

    ; 在下方印出：「Sorry. The Word of the Day was: <正確答案>」
    mov dh, 20
    mov dl, 40
    call GotoXY
    mov edx, OFFSET ending
    call WriteString
    mov edx, correct_word
    call WriteString
    ret
Loser ENDP


;---------------------------------------------------------
; Wordle
; 功能：
;   在畫面上方印出「WORDLE」的 ASCII 標題。
;   通常由 SetDisplay 來呼叫。
;---------------------------------------------------------
Wordle PROC USES eax ebx ecx edx esi
    mov eax, wordleColor
    call SetTextColor

    ; 從 (5, 20) 開始，一行一行印出 waWordy（共 7 行）
    mov bh, 5
    mov bl, 20
    mov ecx, 7
    mov esi, OFFSET waWordy

LoopWordleWA:
        mov dh, bh
        mov dl, bl
        call GotoXY
        mov edx, esi
        call WriteString
        inc bh
        add esi, waWordyRowSize
        loop LoopWordleWA
    ret
Wordle ENDP

END
