INCLUDE Irvine32.inc
INCLUDE logic.inc
INCLUDE wordlist.inc

.code

; ============================================================
; SelectRandomWord
; 功能：
;   從 wordlist 中隨機選一個單字作為「正確答案」(correct_word)
;   回傳值：EDX = 指向隨機單字的位址
;
; wordlistSize：單字數量（每個單字 5 字母 + 1 空字元 = 6 bytes）
; ============================================================
SelectRandomWord PROC USES eax ebx
    mov eax, wordlistSize     ; 取得單字數
    call RandomRange          ; eax = 0 ~ wordlistSize-1 的隨機值

    mov ebx, eax              ; 暫存隨機 index
    mov eax, 6                ; 每個單字占 6 bytes
    mul ebx                   ; eax = 6 * index（要跳過的 byte 數）

    mov edx, OFFSET wordlist  ; wordlist 起始位址
    add edx, eax              ; edx 指向隨機單字位置（回傳值）
    ret
SelectRandomWord ENDP


; ============================================================
; CharInWord
; 功能：
;   檢查某個字母 Char 是否存在於 WordCheck（5 字母單字）中
;   若有找到 → CMP 結果為相等 (ZF=1)
;   若沒找到 → CMP 結果為不相等 (ZF=0)
;
; 備註：
;   這裡並沒有回傳數值，而是透過 cmp 的結果決定 jump。
; ============================================================
CharInWord PROC USES eax ecx esi, Char: BYTE, WordCheck: DWORD
    mov ecx, 5                ; Wordle 單字固定 5 字母
    mov esi, WordCheck

CharInWordLoop:
        mov ah, [esi]         ; 取當前字母
        cmp ah, Char          ; 比對是否相同
        je CharInWordEnd      ; 找到 → 離開（ZF = 1）
        inc esi
        loop CharInWordLoop   ; 檢查下一個字母

CharInWordEnd:
    ret
CharInWord ENDP


; ============================================================
; CharInSamePos
; 功能：
;   檢查兩個字母是否「位置相同且字母相等」
;   若相等 → cmp 設定 ZF=1
; ============================================================
CharInSamePos PROC USES eax, Char1: BYTE, Char2: BYTE
    mov ah, Char1
    cmp ah, Char2             ; 相等 → ZF=1
    ret
CharInSamePos ENDP


; ============================================================
; isWord
; 功能：
;   檢查玩家輸入的單字是否存在於 wordlist 裡
;   若找到 → ZF=1
;   未找到 → ZF=0
;
; 流程：
;   - 一個單字占 6 bytes（5 字母 + 結尾 0）
;   - WordCheck 與列表中的字做比對 (Str_compare)
; ============================================================
isWord PROC USES eax ecx, WordCheck: DWORD
    mov ecx, wordlistSize
    mov eax, OFFSET wordlist

isWordLoop:
        push WordCheck         ; 第一個字串位址
        push eax               ; 第二個字串位址（列表中的一個單字）
        call Str_compare       ; 比較兩字串是否完全相同
        je isWordInList        ; 若相同 → 結束（ZF = 1）

        add eax, 6             ; 移到下一個單字位置
        loop isWordLoop

isWordInList:
    ret
isWord ENDP

END
