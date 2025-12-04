.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

INCLUDE Irvine32.inc
INCLUDE logic.inc
INCLUDE graphics.inc
INCLUDE colors.inc

.data
; 正確答案字串的位址（SelectRandomWord 會回傳至這裡）
correct_word DWORD ?

; 玩家輸入緩衝區（最多輸入 6 字 + 結尾 0）
bufferWord BYTE 7 DUP (?), 0

tries BYTE 0                       ; 第幾次嘗試（0~5）
square_length BYTE 50             ; Wordle 輸入方框的 X 起始位置
square_height BYTE 15             ; Wordle 輸入方框的 Y 起始位置

try_again BYTE "Play again? [y/n] ",0

.code
main PROC PUBLIC

    call Randomize        ; 初始化隨機種子

GameOn:
    ; ---------------------------------------------------
    ; 隨機挑一個正確答案
    ; ---------------------------------------------------
    call SelectRandomWord ; edx = 正確答案位址
    mov correct_word, edx ; 存進變數，後面所有流程會用到
    mov tries, 0          ; 重設嘗試次數

    ; ---------------------------------------------------
    ; 初始化畫面：背景、WORDLE 標題、6 列輸入框
    ; ---------------------------------------------------
    call SetDisplay

; -------------------------------------------------------
; 每一輪（一列）輸入一個 5 字母單字
; -------------------------------------------------------
LoopRows:

    ; 移動游標到對應列（square_height + tries）
    mov dh, square_height
    add dh, tries
    mov dl, square_length
    call GotoXY

    ; ---------------------------------------------------
    ; 讀取玩家輸入
    ; ---------------------------------------------------
    mov ecx, 7                      ; 最長輸入長度
    mov edx, OFFSET bufferWord
    mov eax, (tableBackground * 16) + fontColor ; 淺藍底 + 白字
    call SetTextColor
    call ReadString                 ; eax 回傳輸入字元數

    ; ---------------------------------------------------
    ; 檢查輸入長度必須 = 5
    ; ---------------------------------------------------
    cmp eax, 5
    jne Error

    ; ---------------------------------------------------
    ; 檢查輸入單字是否在字典裡
    ; ---------------------------------------------------
    push OFFSET bufferWord
    call isWord
    jne Error

    jmp LoopNoError

; -------------------------------------------------------
; 錯誤處理：長度不符 / 不在字典
; -------------------------------------------------------
Error:
    movzx ebx, tries
    push ebx
    call ClearLine
    call DisplayError
    jmp DoLoopRows

; -------------------------------------------------------
; 若 input 正確 → 回到下一列邏輯
; -------------------------------------------------------
DoLoopRows:
    loop LoopRows

; -------------------------------------------------------
; 處理有效輸入
; -------------------------------------------------------
LoopNoError:

    ; 回到該列開頭，準備顯示顏色方塊
    mov dh, square_height
    add dh, tries
    mov dl, square_length
    call GotoXY

    ; 檢查每個字元的狀態，並顯示顏色
    push correct_word
    push OFFSET bufferWord
    call CheckWord

    ; ---------------------------------------------------
    ; 判斷是否猜中（字串完全相同）
    ; ---------------------------------------------------
    push correct_word
    push OFFSET bufferWord
    call Str_compare
    je DisplayWinner

    ; ---------------------------------------------------
    ; 還沒猜中 → 進入下一列
    ; ---------------------------------------------------
    inc tries
    cmp tries, 6
    je DisplayLoser        ; 6 次用完 → 輸

    jmp DoLoopRows

; -------------------------------------------------------
; 六次猜完仍沒達成 → 輸了
; -------------------------------------------------------
DisplayLoser:
    push correct_word
    call Loser
    jmp Stop

; -------------------------------------------------------
; 猜中！顯示勝利畫面
; -------------------------------------------------------
DisplayWinner:
    call Winner

; -------------------------------------------------------
; 詢問是否再玩一局
; -------------------------------------------------------
Stop:
    mov dl, 25
    mov dh, 25
    call GotoXY
    mov eax, fontColor
    call SetTextColor
    mov edx, OFFSET try_again
    call WriteString

TryAgainPrompt:
    call ReadChar
    cmp al, 'y'
    je GameOn
    cmp al, 'n'
    jne TryAgainPrompt

    INVOKE ExitProcess, 0

main ENDP
END main
