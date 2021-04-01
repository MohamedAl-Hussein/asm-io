TITLE AssemblyIO

; Author: Mohamed Al-Hussein
; Description: 
;     Program consists of custom macros to read and write strings to/from the console. 
;     Also includes procedures to read an ASCII string integer and convert it to an integer, and vice versa.
;     Includes macro for exception handling.
;     Program starts with a test procedure that asks user for 10 digits before displaying them as an array, their sum,
;     and their average.

INCLUDE Irvine32.inc

ARR_LEN = 10d                                               ; length of array used for test procedure 
ARR_LEN_STR TEXTEQU <">, %ARR_LEN, <">                      ; array length as an ASCII string
ARR_SIZE = ARR_LEN * TYPE DWORD                             ; size of input array

INPUT_BUFFER_LEN = 50d                                      ; max length of string that can be read from console - 1

FONT_COLOR = white                                          ; console text color (default)

SPACE = 20h                                                 ; ASCII space character
CARRET = 0Dh                                                ; ASCII carriage return character
LINEFEED = 0Ah                                              ; ASCII line feed character
NULL = 0h                                                   ; ASCII null character 

NEWLINE EQU CARRET, LINEFEED                                ; new line
EOL EQU NEWLINE, NULL                                       ; end of line

.STACK 1024
.DATA
    ; general messages
    introMsg        BYTE    "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", NEWLINE, "Written by: ",
                            "Mohamed Al-Hussein.", NEWLINE, EOL
    rules           BYTE    "Please provide ", ARR_LEN_STR, " signed decimal integers.", NEWLINE, "Each number needs ", 
                            "to be small enough to fit inside a 32 bit register.", NEWLINE, "After you have finished ", 
                            "inputting the raw numbers, I will display a list of the integers, their sum, and their ", 
                            "average value.", NEWLINE, EOL 
    outroMsg        BYTE    2 DUP(NEWLINE), "Thanks for playing!", EOL

    ; prompts
    inputPrompt     BYTE    "Please provide a signed number: ", NULL
    inputReprompt   BYTE    "Please try again: ", NULL
    tryAgainMsg     BYTE    "Please try again: ", NULL

    ; display titles
    arrayTitle      BYTE    NEWLINE, "You entered the following numbers:", EOL
    sumTitle        BYTE    NEWLINE, "The sum of these numbers is: ", NULL
    avgTitle        BYTE    NEWLINE, "The rounded average is: ", NULL

    outputBuffer    BYTE    (INPUT_BUFFER_LEN + 1) DUP(?)
    intInput        DWORD   ?

    arrDelimiter    BYTE    ", ", NULL

.CODE
main PROC

    ; exit to operating system
    INVOKE          ExitProcess, 0
main ENDP

END main
