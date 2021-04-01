TITLE AssemblyIO

; Author: Mohamed Al-Hussein
; Description: 
;     Program consists of custom macros to read and write strings to/from the console. 
;     Also includes procedures to read an ASCII string integer and convert it to an integer, and vice versa.
;     Includes macro for exception handling.
;     Program starts with a test procedure that asks user for 10 digits before displaying them as an array, their sum,
;     and their average.

INCLUDE Irvine32.inc

; ----------------------------------------------------------------------------------------------------------------------
; Name: mExceptionHandler
;
; Given a valid error-code, displays a custom error message to the console.
;
; Preconditions:
;     1. The error code provided is a DWORD integer.
;     2. The error code is defined within the macro. Undefined error codes will not raise any warnings.
;
; Receives:
;     errorCode             = An integer denoting an error code
;
; Error Code Table:
;     98                    OverflowError
;     97                    TypeError - invalid signed integer
;     0                     No error
; ----------------------------------------------------------------------------------------------------------------------
mExceptionHandler MACRO errorCode
    LOCAL errorNotInt, errorOV
    LOCAL _noError, _notInt, _overflow, _throwError

    ERROR_NOT_INT = 98d                                     ; error code for non integer 
    ERROR_OVERFLOW = 97d                                    ; error code for overflow 

    ERROR_MSG_COLOR = lightRed                              ; console text color (error messages)
    BACKGROUND_COLOR = black * 16                           ; console text background color

    .DATA
      errorNotInt   BYTE    "TypeError: Value provided is not a signed integer.", 13, 10, 0 
      errorOV       BYTE    "OverflowError: Value provided is too large or too small to fit in destination operand.", 
                            13, 10, 0 

    .CODE
; ---------------------------------------------------------------------------
; STEP 1: Test if errorCode is 0 in which case there is no error.
; ---------------------------------------------------------------------------
      MOV         EAX, errorCode
      TEST        EAX, EAX
      JZ          _noError

; ---------------------------------------------------------------------------
; STEP 2: Search all known error codes for a match. 
; ---------------------------------------------------------------------------
      CMP         EAX, ERROR_NOT_INT
      JE          _notInt
      CMP         EAX, ERROR_OVERFLOW
      JE          _overflow

; ---------------------------------------------------------------------------
; STEP 3: No match was found, so we can stop searching. 
; ---------------------------------------------------------------------------
      JMP         _noError

; ---------------------------------------------------------------------------
; STEP 4: If a match was found, display its error message. 
; ---------------------------------------------------------------------------
_notInt:
      PUSH        OFFSET errorNotInt 
      JMP         _throwError

_overflow:
      PUSH        OFFSET errorOV
      JMP         _throwError 

_throwError:
      PUSH        ERROR_MSG_COLOR
      PUSH        BACKGROUND_COLOR
      CALL        displayErrorMsg 

_noError:
ENDM

; ----------------------------------------------------------------------------------------------------------------------
; Name: mGetString
; 
; Displays a prompt to the user to enter a string and stores it at the address of the provided output argument.
;
; Preconditions:
;     1. *prompt[] is a null-terminated string.
;	  2. *outputBuffer[] is an array of BYTEs.
;     3. bytesRead is a DWORD.
;     4. bufferLength >= len(*outputBuffer[] + 1) > 0.
;
; Receives:
;     prompt                = Address of message to display as prompt.
;     outputBuffer          = Address of the variable to write the string input to.
;     bufferLength		    = Length of the array at the address of the outputBuffer.
;     bytesRead 		    = Address of variable to write the number of bytes read from input.
;
; Returns:
;     *outputBuffer[]       = Input string provided by user.
;     *bytesRead            = Total number of bytes read from input.
; ----------------------------------------------------------------------------------------------------------------------
mGetString MACRO prompt, outputBuffer, bufferLength, bytesRead 
    PUSH            EAX
    PUSH            ECX
    PUSH            EDX
    PUSH            EDI

; ---------------------------------------------------------------------------
; STEP 1: Prompt user for input. 
; ---------------------------------------------------------------------------
    mDisplayString  prompt

; ---------------------------------------------------------------------------
; STEP 2a: Store input into outputBuffer. 
; ---------------------------------------------------------------------------
    MOV             EDX, outputBuffer
    MOV             ECX, bufferLength
    CALL            ReadString

; ---------------------------------------------------------------------------
; STEP 2b: Store number of bytes read. 
; ---------------------------------------------------------------------------
    MOV             EDI, bytesRead
    MOV             [EDI], EAX

    POP             EDI
    POP             EDX
    POP             ECX
    POP             EAX
ENDM

; ----------------------------------------------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays a string at a given input address to the console.
;
; Preconditions:
;     1. *inputBuffer[] is a null-terminated string. 
;
; Receives:
;     inputBuffer           = Address of the string variable to write to the console.
; ----------------------------------------------------------------------------------------------------------------------
mDisplayString MACRO inputBuffer
    PUSH            EDX

    ; display provided string
    MOV             EDX, inputBuffer
    CALL            WriteString

    POP             EDX
ENDM

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

; ----------------------------------------------------------------------------------------------------------------------
; Name: configureConsoleSettings
;
; Configures console window text color and background color.
;
; Preconditions:
;     1. FONT_COLOR and BACKGROUND_COLOR are valid color values as per Irvine guidelines.
;
; Recieves:
;     [EBP + 12]            = FONT_COLOR 
;     [EBP + 8]             = BACKGROUND_COLOR 
; ----------------------------------------------------------------------------------------------------------------------
configureConsoleSettings PROC
    PUSH            EBP
    MOV             EBP, ESP
    PUSH            EAX

; ---------------------------------------------------------------------------
; STEP 1: Set text font and background color.
; ---------------------------------------------------------------------------
    MOV             EAX, [EBP + 12]                         ; EAX = FONT_COLOR 
    ADD             EAX, [EBP + 8]                          ; EAX += BACKGROUND_COLOR 
    CALL            SetTextColor

; ---------------------------------------------------------------------------
; STEP 2: Apply background color to entire window. 
; ---------------------------------------------------------------------------
    CALL			Clrscr									

    POP				EAX
    MOV             ESP, EBP
    POP             EBP
    RET             8
configureConsoleSettings ENDP

; ---------------------------------------------------------------------------------------------------- 
; Name: displayErrorMsg 
; 
; Displays error message in ERROR_MSG_COLOR to user.
;
; Preconditions: 
;     1. errorCode > 0 
;     2. errorMsg is a null-terminated string.
;     3. ERROR_MSG_COLOR, BACKGROUND_COLOR are valid color values as per Irvine guidelines.
;
; Receives:
;	  [EBP + 16]            = &errorMsg[]
;     [EBP + 12]            = ERROR_MSG_COLOR
;     [EBP + 8]             = BACKGROUND_COLOR
; ---------------------------------------------------------------------------------------------------- 
displayErrorMsg PROC
    PUSH			EBP
    MOV				EBP, ESP	
    PUSH			EAX
    PUSH			EBX
    PUSH			EDX

; ---------------------------------------------------------------------------
; STEP 1: Save current text and background colors. 
; ---------------------------------------------------------------------------
    XOR				EBX, EBX
    CALL			GetTextColor								
    MOVZX			EBX, AL

; ---------------------------------------------------------------------------
; STEP 2: Set text and background colors for error message then display error 
;         message. 
; ---------------------------------------------------------------------------
    MOV             EAX, [EBP + 12]                         ; EAX = ERROR_MSG_COLOR
    ADD             EAX, [EBP + 8]                          ; EAX += BACKGROUND_COLOR
    CALL			SetTextColor

    mDisplayString  [EBP + 16]                              ; print(*errorMsg[])

; ---------------------------------------------------------------------------
; STEP 3: Restore text and background colors. 
; ---------------------------------------------------------------------------
    MOV				EAX, EBX
    CALL			SetTextColor

    POP				EDX
    POP				EBX
    POP				EAX
    POP				EBP
    RET			    12	
displayErrorMsg ENDP

END main
