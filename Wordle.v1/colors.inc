; 基本顏色
backgroundColor equ navy
tableBackground equ lightBlue
fontColor       equ white

; correction highlights
highlightCorrectCharBG equ yellow
highlightCorrectCharFG equ black
highlightCorrectPosBG equ lightYellow  
highlightCorrectPosFG equ white

highlightCorrectChar equ (16 * highlightCorrectCharBG) + highlightCorrectCharFG
highlightCorrectPos equ (16 * highlightCorrectPosBG) + highlightCorrectPosFG

; ascii art fonts
wordleFG equ lightCyan
winnerFG equ lightCyan
loserFG equ lightRed

wordleColor equ (16 * backgroundColor) + wordleFG
winnerColor equ (16 * backgroundColor) + winnerFG
loserColor equ (16 * backgroundColor) + loserFG

     

