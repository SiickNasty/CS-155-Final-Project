;**********************************************************;
; Nathan Abrantes -- ASCII Calculator 
; 25 April 2026 
;   
; R0 = Used for string addresses, character input/output
; R1 = Used for ('y' / 'Y')
; R5 = Holds subroutine addresses for JSRR calls
; R7 = Return address automatically managed by JSRR
;
;**********************************************************;

.ORIG x3000 

MAIN
    ; Load intro message and print it
    LD R0, ADDR_INTRO
    PUTS

CALC_LOOP
    ; R0 = address of clear-screen string
    LD R0, ADDR_CLEAR
    PUTS

    ; R0 = address of calculator frame
    LD R0, ADDR_FRAME
    PUTS

    ; Call READ_INPUT subroutine
    ; R5 = subroutine address
    LD R5, P_READ
    JSRR R5

    ; Call COMPUTE subroutine
    ; R5 = subroutine address
    LD R5, P_COMPUTE
    JSRR R5

    ; Call DRAW_RESULT subroutine
    ; R5 = subroutine address
    LD R5, P_DRAW
    JSRR R5

    ; Ask user if they want to calculate again
    ; R0 = address of prompt string
    LD R0, ADDR_AGAIN
    PUTS

    ; R0 = user character input
    GETC
    OUT
    
    ; Check for lowercase 'y'
    ; R1 = R0 - 'y'
    LD R1, V_NEG_Y
    ADD R1, R0, R1
    BRz CALC_LOOP_JUMP
    
    ; Check for uppercase 'Y'
    ; R1 = R0 - 'Y'
    LD R1, V_NEG_Y_CAP
    ADD R1, R0, R1
    BRz CALC_LOOP_JUMP

    ; Print goodbye message
    ; R0 = address of goodbye string
    LD R0, ADDR_BYE
    PUTS

    HALT

; Helper jump for the branch (BR)
CALC_LOOP_JUMP
    ; R5 = address of CALC_LOOP
    LD R5, P_MAIN_LOOP
    JMP R5

; Pointers for MAIN (offset issue stuff)
P_MAIN_LOOP   .FILL CALC_LOOP
P_READ        .FILL READ_INPUT
P_COMPUTE     .FILL COMPUTE
P_DRAW        .FILL DRAW_RESULT
ADDR_INTRO    .FILL STR_INTRO
ADDR_CLEAR    .FILL STR_DE_CLEAR
ADDR_FRAME    .FILL STR_DE_FRAME
ADDR_AGAIN    .FILL STR_AGAIN
ADDR_BYE      .FILL STR_BYE

; ASCII offsets
V_NEG_Y       .FILL #-121    ; -'y'
V_NEG_Y_CAP   .FILL #-89     ; -'Y'

; --- Globals ---
NUM_A    .BLKW 1   ; first number
NUM_B    .BLKW 1   ; second number
OP_CHAR  .BLKW 1   ; operator character
RESULT   .BLKW 1   ; calculation result

;***********************************
; Subroutine: READ_INPUT
; Reads the 
; R0 = Stores input characters and converted numeric values
; R1 = ASCII conversion offset (-48)
; R7 = Saved/restored return address
;***********************************
READ_INPUT
    ; R7 = caller return address
    ST R7, SAVER7_RI
    
    ; Print prompt
    ; R0 = address of prompt string
    LD R0, ADDR_PROMPT
    PUTS

    ; Read first digit
    ; R0 = ASCII digit
    ; R1 = ASCII  offset (-48)
    GETC
    OUT
    LD R1, V_ASCII_OFF
    ADD R0, R0, R1      
    ST R0, NUM_A

    ; Read operator
    ; R0 = operator character
    GETC
    OUT
    ST R0, OP_CHAR

    ; Read second digit
    ; R0 = ASCII digit
    ; R1 = ASCII offset (-48)
    GETC
    OUT
    LD R1, V_ASCII_OFF
    ADD R0, R0, R1      
    ST R0, NUM_B

    ; Print newline
    ; R0 = newline character
    LD R0, V_NEWLINE
    OUT

    ; Restore return address
    LD R7, SAVER7_RI
    RET

SAVER7_RI    .BLKW 1
ADDR_PROMPT  .FILL STR_PROMPT
V_ASCII_OFF  .FILL #-48
V_NEWLINE    .FILL #10

;*******************************************************;
; Subroutine: COMPUTE
; R0 = Final calculation result
; R1 = NUM_A (first operand)
; R2 = NUM_B (second operand / loop counter / divisor)
; R3 = Operator character
; R4 = Temporary comparison register
; R7 = Saved/restored return address
;*******************************************************;
COMPUTE
    ; Save return address
    ST R7, SAVER7_CP

    ; Load operands and operator
    ; R1 = NUM_A
    ; R2 = NUM_B
    ; R3 = operator
    LD R1, NUM_A
    LD R2, NUM_B
    LD R3, OP_CHAR

    ; Check for '+'
    ; R4 = R3 - '+'
    LD R4, V_NEG_PLUS
    ADD R4, R3, R4
    BRz DO_ADD

    ; Check for '-'
    LD R4, V_NEG_MINUS
    ADD R4, R3, R4
    BRz DO_SUB

    ; Check for '*'
    LD R4, V_NEG_STAR
    ADD R4, R3, R4
    BRz DO_MUL

    ; Otherwise perform division
    BR  DO_DIV

DO_ADD
    ; R0 = R1 + R2
    ADD R0, R1, R2
    BR DONE_COMP

DO_SUB
    ; R0 = R1 - R2
    ; Convert R2 to negative using 2's complement
    NOT R2, R2
    ADD R2, R2, #1
    ADD R0, R1, R2
    BR DONE_COMP

DO_MUL
    ; Multiplication by repeated addition
    ; R0 = running total
    ; R1 = multiplicator
    ; R2 = loop counter
    AND R0, R0, #0
    ADD R2, R2, #0
    BRz DONE_COMP

MUL_LP
    ADD R0, R0, R1
    ADD R2, R2, #-1
    BRp MUL_LP
    BR DONE_COMP

DO_DIV
    ; Division by repeated subtraction
    ; R0 = quotient
    ; R1 = dividend
    ; R2 = negative divisor
    AND R0, R0, #0

    ; Prevent divide by zero
    ADD R2, R2, #0
    BRz DONE_COMP

    ; Convert divisor to negative
    NOT R2, R2
    ADD R2, R2, #1 

DIV_LP
    ADD R1, R1, R2
    BRn DONE_COMP
    ADD R0, R0, #1
    BR DIV_LP

DONE_COMP
    ; Store final result
    ST R0, RESULT

    ; Restore return address
    LD R7, SAVER7_CP
    RET

SAVER7_CP   .BLKW 1
V_NEG_PLUS  .FILL #-43
V_NEG_MINUS .FILL #-45
V_NEG_STAR  .FILL #-42

;************************************************;
; SUBROUTINE: DRAW_RESULT
; R0 = Character output / values to print
; R1 = ASCII conversion value (0)
; R5 = Address of SIMPLE_PRINT_NUM
; R7 = Saved/restored return address
;************************************************;
DRAW_RESULT
    ; Save return address
    ST R7, SAVER7_DR
    
    ; Clear screen
    ; R0 = clear string address
    LD R0, ADDR_CLEAR_2
    PUTS

    ; Print top of result frame
    ; R0 = frame string address
    LD R0, ADDR_PRE
    PUTS

    ; Print first number
    ; R0 = NUM_A
    ; R1 = ASCII '0'
    LD R0, NUM_A
    LD R1, V_CHAR_ZERO
    ADD R0, R0, R1
    OUT

    ; Print space
    LD R0, V_SPACE
    OUT

    ; Print operator
    LD R0, OP_CHAR
    OUT

    ; Print space
    LD R0, V_SPACE
    OUT

    ; Print second number
    ; R0 = NUM_B
    ; R1 = ASCII 0
    LD R0, NUM_B
    LD R1, V_CHAR_ZERO
    ADD R0, R0, R1
    OUT

    ; Print middle frame section
    LD R0, ADDR_MID
    PUTS

    ; Load result
    ; R0 = RESULT
    LD R0, RESULT

    ; Check if result is negative
    BRn IS_NEG
    BR  PRINT_VAL

IS_NEG
    ; Print minus sign
    LD R0, V_DASH
    OUT

    ; Convert result back to positive
    LD R0, RESULT
    NOT R0, R0
    ADD R0, R0, #1

PRINT_VAL
    ; Call SIMPLE_PRINT_NUM
    ; R5 = subroutine address
    LD R5, P_SPN
    JSRR R5

    ; Print bottom frame
    LD R0, ADDR_POST
    PUTS

    ; Restore return address
    LD R7, SAVER7_DR
    RET

SAVER7_DR     .BLKW 1
P_SPN         .FILL PRINT_NUM
ADDR_CLEAR_2  .FILL STR_DE_CLEAR
ADDR_PRE      .FILL STR_DR_PRE
ADDR_MID      .FILL STR_DR_MID
ADDR_POST     .FILL STR_DR_POST
V_CHAR_ZERO   .FILL x30
V_SPACE       .FILL x20
V_DASH        .FILL x2D

;**************************************************;
; SUBROUTINE: PRINT_NUM
; R0 = Number being printed / remainder digit
; R1 = Tens digit counter
; R2 = Constant values (-10, ASCII 0)
; R3 = Temporary subtraction result
; R7 = Saved/restored return address
;**************************************************;
PRINT_NUM
    ; Save return address
    ST R7, SAVER7_SPN

    ; Save original number
    ; R0 = number to print
    ST R0, TEMP_VAL

    ; R1 = tens digit counter
    AND R1, R1, #0 

    ; R2 = -10
    LD R2, V_NEG_TEN

TENS_LP
    ; R3 = R0 - 10
    ADD R3, R0, R2
    BRn DONE_TENS

    ; Reduce number by 10
    ADD R0, R3, #0

    ; Increment tens counter
    ADD R1, R1, #1
    BR TENS_LP

DONE_TENS
    ; If tens digit is 0, skip printing
    ADD R1, R1, #0
    BRz SKIP_TENS

    ; Convert tens digit to ASCII and print
    LD R2, V_CHAR_ZERO_2
    ADD R0, R1, R2
    OUT

SKIP_TENS
    ; Restore original value
    LD R0, TEMP_VAL

    ; R2 = -10
    LD R2, V_NEG_TEN

REM_LP
    ; Repeated subtraction to find remainder
    ; R3 = R0 - 10
    ADD R3, R0, R2
    BRn FINISH

    ADD R0, R3, #0
    BR REM_LP

FINISH
    ; Convert ones digit to ASCII and print
    LD R2, V_CHAR_ZERO_2
    ADD R0, R0, R2
    OUT

    ; Restore return address
    LD R7, SAVER7_SPN
    RET

;********************************;
;            DATA
;********************************;
SAVER7_SPN     .BLKW 1
TEMP_VAL       .BLKW 1
V_NEG_TEN      .FILL #-10
V_CHAR_ZERO_2  .FILL x30

STR_INTRO    .STRINGZ "\nWelcome to my Calculator!!!\n"
STR_DE_CLEAR .STRINGZ "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
STR_DE_FRAME .STRINGZ "+----------------+\n|   ASCII CALC   |\n+----------------+\n| INPUT:         |\n| RESULT:        |\n+----------------+\n"
STR_PROMPT   .STRINGZ "Enter Calculation (ex. 5+4): "
STR_DR_PRE   .STRINGZ "+----------------+\n|   ASCII CALC   |\n+----------------+\n| INPUT:  "
STR_DR_MID   .STRINGZ "\n| RESULT: "
STR_DR_POST  .STRINGZ "\n+----------------+\n"
STR_AGAIN    .STRINGZ "\nAgain? (y/n): "
STR_BYE      .STRINGZ "\nBye! Have a great time!\n"

.END