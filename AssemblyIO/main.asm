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

; ----------------------------------------------------------------------------------------------------------------------
; Name: ReadVal
;
; Displays a prompt to the user to enter a SDWORD integer; then converts the string input from ASCII digits into an 
; integer and stores it at the output address provided.
;
; Validates user input by checking for invalid characters, and for overflow from passing too big of a value.
;
; Preconditions:
;     1. *outputVal is a SDWORD variable.
;     2. *prompt[] and *reprompt[] are null-terminated strings.
;     3. *outputVal is a SDWORD type.
;     4. *outputBuffer[] is an array of BYTEs.
;     5. bufferLength >= len(*outputBuffer[]) > 0.
;
; Receives:
;     [EBP + 24]            = &reprompt[]
;                                 Address of message to display as a re-prompt.
;     [EBP + 20]            = &prompt[]
;                                 Address of message to display as prompt.
;     [EBP + 16]            = &outputBuffer[]
;                                 Address of the variable to write the string input to.
;     [EBP + 12]            = bufferLength
;                                 Length of the array at the address of the outputBuffer.
;     [EBP + 8]             = &outputVal 
;                                 Address of variable to write the converted integer to.
;
; Local Variables:
;     strLen                = number of bytes read from input
;     output                = temporary variable to store converted string
;     errorCode             = stores any error codes returned during conversion step
;
; Returns:
;     *outputVal		    = Valid input converted to an integer.
; ----------------------------------------------------------------------------------------------------------------------
ReadVal PROC
    LOCAL           strLen:DWORD, output:SDWORD, errorCode:DWORD
    PUSH            EAX
    PUSH            EBX
    PUSH            EDI

; ---------------------------------------------------------------------------
; STEP 1: Get input from user and validate it. Then convert it to an integer.
; ---------------------------------------------------------------------------
    ; prompt user for a signed integer
    LEA             EDI, strLen                             
    mGetString      [EBP + 20], [EBP + 16], [EBP + 12], EDI

; --------------------------------------------------  
; _convertInput:
;     Convert user input into an integer.
;     
;     If the conversion returned an error, ask
;     user to provide another value.
; --------------------------------------------------  
_convertInput:
    ; convert user input to integer
    PUSH            [EBP + 16]                              ; arg0 = &outputBuffer[]
    PUSH            strLen                                  ; arg1 = bytesRead
    LEA             EDI, output 
    PUSH            EDI                                     ; arg2 = *output 
    LEA             EDI, errorCode                          
    PUSH            EDI                                     ; arg3 = *errorCode
    CALL            ASCIIToInt   

    ; check error code to see if anything went wrong
    MOV             EAX, errorCode
    TEST            EAX, EAX                                ; if (errorCode == 0):
    JZ              _storeResult                            ;     goto _storeResult
    mExceptionHandler errorCode                             ; else: raise exception(*errorCode)

    ; display reprompt message and ask for another value
    LEA             EDI, strLen                             
    mGetString      [EBP + 24], [EBP + 16], [EBP + 12], EDI 

    JMP             _convertInput

; ---------------------------------------------------------------------------
; STEP 2: Store converted input. 
; ---------------------------------------------------------------------------
; --------------------------------------------------  
; _storeResult:
;     Store converted value into outputVal.
; --------------------------------------------------  
_storeResult:
    MOV             EDI, [EBP + 8]                          ; EDI = &outputVal
    MOV             EAX, output
    MOV             [EDI], EAX                              ; *outputVal = output

    POP             EDI
    POP             EBX
    POP             EAX
	RET             20 
ReadVal ENDP

; ----------------------------------------------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a SDWORD integer to a string of ASCII digits and displays it to the console.
;
; Preconditions:
;     inputVal is a SDWORD integer.
;
; Receives:
;     inputVal			    = The integer to convert.
;
; Local Variables:
;     printStr              = Byte array to store string representation of integer in. 
; ----------------------------------------------------------------------------------------------------------------------
WriteVal PROC
    LOCAL           printStr[12]:BYTE
    PUSH            ESI
    PUSH            EDI

; ---------------------------------------------------------------------------
; STEP 1: Convert integer input to string.
; ---------------------------------------------------------------------------
    PUSH            [EBP + 8]                               ; arg0 = inputVal
    LEA             EDI, printStr 
    PUSH            EDI                                     ; arg1 = &printStr[]
    CALL            intToASCII   

; ---------------------------------------------------------------------------
; STEP 2: Display converted input.
; ---------------------------------------------------------------------------
    LEA             ESI, printStr
    mDisplayString  ESI                                     ; print(str(inputVal))

    POP             EDI
    POP             ESI
    RET             4
WriteVal ENDP

; ----------------------------------------------------------------------------------------------------------------------
; Name: ASCIIToInt 
;
; Converts a digit string to a signed DWORD integer.
;
; Validates input for invalid characters and too large of an input.
;
; Preconditions:
;     1. *input[] is a BYTE array.
;     2. strLen >= len(*input[]).
;     3. strLen is a DWORD.
;     4. *output is a SDWORD.
;     5. *errorCode is a DWORD and equal to 0. 
;
; Receives:
;     [EBP + 20]            = &input[]
;                                 Input string to convert.
;     [EBP + 16]            = strLen
;                                 Length of input string.
;     [EBP + 12]            = &output
;                                 Address of variable to store result in.
;     [EBP + 8]             = &errorCode
;                                 Address of variable to store error code in.
;
; Local Variables:
;     result                = holds converted value of integer string
;     position              = tracks index position in integer string
;     temp                  = temporary placeholder to store result of 10^position
;     sign                  = integer value for the integer string's sign (-1 for negative, 1 for positive)
;     digitsScanned         = tracks number of digits scanned to prevent hard-to-detect overflow conditions
;     lastDigitScanned      = holds the most recent digit scanned, to use for detecting leading zeros
;
; Returns:
;     *output               = int(*input[])
;     *errorCode            = 98: Not a valid integer
;                             97: Number too big
;                             0: No error
; ----------------------------------------------------------------------------------------------------------------------
ASCIIToInt PROC
    LOCAL           result:SDWORD, position:DWORD, temp:SDWORD, sign:SDWORD, digitsScanned:DWORD, lastDigitScanned:DWORD
    PUSH            EAX
    PUSH            EBX
    PUSH            ECX
    PUSH            EDX
    PUSH            ESI
    PUSH            EDI

; ---------------------------------------------------------------------------
; STEP 1: Initialize local variables.
; ---------------------------------------------------------------------------
    ; initialize variables
    MOV             result, 0
    MOV             position, 0
    MOV             digitsScanned, 0

    ; assume input is positive
    MOV             sign, 1                                 

; ---------------------------------------------------------------------------
; STEP 2: Check if provided string is empty. 
; ---------------------------------------------------------------------------
    XOR             ECX, ECX
    MOV             EAX, [EBP + 16]                         ; EAX = strLen
    TEST            EAX, EAX                                ; if (strLen == 0):
    JZ              _notDigit                               ;     goto _notDigit

; ---------------------------------------------------------------------------
; STEP 3: Determine if input is positive or negative. 
; ---------------------------------------------------------------------------
    MOV             ESI, [EBP + 20]                         ; ESI = &input[] 
    MOV             AL, BYTE PTR [ESI]                      ; EAX = *input[0]
    CMP             EAX, '-'                                ; if (EAX != '-'):
    JNE             _goToEndOfString                        ;     goto _goToEndOfString
    MOV             sign, -1                                ; sign = -1

; ---------------------------------------------------------------------------
; STEP 4: Go to end of input string and move backwards. 
; ---------------------------------------------------------------------------
; --------------------------------------------------  
; _goToEndOfString:
;     Move to end of string, just before the 
;     null-terminator.
; --------------------------------------------------  
_goToEndOfString:
    MOV             ECX, [EBP + 16]                         ; ECX = strLen 
    ADD             ESI, ECX                                ; ESI = &input[-1] 
    DEC             ESI                                     ; ESI = &input[-2] 
    STD

; ---------------------------------------------------------------------------
; STEP 5: Convert string input to its integer representation. Check for any
;         errors along the way.
; ---------------------------------------------------------------------------
; --------------------------------------------------  
; _byteToInt:
;     Convert each byte to a digit and add its 
;     positional value to the total.
;
;     Check for any invalid input or overflow and 
;     and throw an error if any are found.
; --------------------------------------------------  
_byteToInt:
    XOR             EAX, EAX
    LODSB                                                   ; currVal = AL = *input[offset]; offset -= 1

; ---------------------------------------------------------------------------
; STEP 5a: Check if value at current position is a digit. 
; ---------------------------------------------------------------------------
    CMP             AL, 30h                                 ; if (currVal < 30h):
    JB              _notDigit                               ;     goto _notDigit
    CMP             AL, 39h                                 ; elif (currVal > 39h):
    JA              _notDigit                               ;     goto _notDigit

    INC             DWORD PTR digitsScanned

; ---------------------------------------------------------------------------
; STEP 5b: Convert value at current position into an integer. 
; ---------------------------------------------------------------------------
    SUB             AL, 30h                                 ; AL = currVal - '0' 

    MOV             lastDigitScanned, EAX 

; ---------------------------------------------------------------------------
; STEP 5c: Compute the digit's numerical value according to its position.
;
;          Then check if computation caused any overflow.
; ---------------------------------------------------------------------------
    MOV             EBX, 10
    PUSH            EBX                                     ; arg0 = 10
    PUSH            position                                ; arg1 = position
    LEA             EBX, temp
    PUSH            EBX                                     ; arg2 = *temp
    CALL            pow32                                   ; *temp = 10 ^ position

    IMUL            temp                                    ; EAX = (currVal - '0') * (10 ^ position)
    JO              _overflow                               ; if (OV == 1): goto _overflow

; ---------------------------------------------------------------------------
; STEP 5d: Multiply result of computation by the input's sign and add it to
;          the running total.
;
;          Then check if addition caused any overflow.
; ---------------------------------------------------------------------------
    MOV             EBX, sign                               ; EBX = sign
    IMUL            EBX                                     ; EAX = sign * ((currVal - '0') * (10 ^ position))

    ADD             result, EAX                             ; result += sign * ((currVal - '0') * (10 ^ position))
    JO              _overflow                               ; if (OV == 1): goto _overflow

    INC             position                                ; position += 1
    LOOP            _byteToInt

; ---------------------------------------------------------------------------
; STEP 6: Make some final checks to make sure input was valid.
; ---------------------------------------------------------------------------
; --------------------------------------------------  
; _checkLeadingZeros:
;     Don't produce an overflow error if digit is 
;     front-padded with zeros. 
; --------------------------------------------------  
    CLD
    XOR             EAX, EAX
    MOV             ESI, [EBP + 20]                         ; ESI = &input[]
    LODSB                                                   ; EAX = *input[0]
    SUB             EAX, 30h                                ; EAX = int(*input[0])
_checkLeadingZeros:
    TEST            EAX, EAX                                ; if (*input[0] == 0 || (*input[0] in {+, -} && *input[1] == 0)):
    JZ              _clearErrorCode                         ;     goto _clearErrorCode

; --------------------------------------------------  
; _checkInputLen:
;     Check total number of digits scanned and throw
;     and overflow error if it exceeds the maximum
;     digits possible for an SDWORD (max of 10 digits).
; --------------------------------------------------  
_checkInputLen:
    MOV             EBX, digitsScanned
    CMP             EBX, 10                                 ; if (digitsScanned > 10):
    JG              _overflow                               ;     goto _overflow
    JMP             _clearErrorCode                         ; else: goto _clearErrorCode

; --------------------------------------------------  
; _notDigit:
;     Determine if non-digit is the input's sign, or
;     if it appears in middle of string.
; --------------------------------------------------  
    CLD
    XOR             EAX, EAX
    MOV             ESI, [EBP + 20]                         ; ESI = &input[]
    LODSB                                                   ; EAX = *input[0]
_notDigit:
    ; non-digit in middle of input string
    CMP             ECX, 1                                  ; if (ECX != 1):
    JNE             _invalidInput                           ;     goto _invalidInput

    ; non-digit is not a valid sign
    CMP             EAX, '-'                                ; if (*input[0] == '-'):
    JE              _validSign                              ;     goto _validSign
    CMP             EAX, '+'                                ; elif (*input[0] != '+'):
    JNE             _invalidInput                           ;     goto _invalidInput

; --------------------------------------------------  
; _validSign:
;     If sign is valid, check input for leading zeros
;     or too many digits.
; --------------------------------------------------  
_validSign:
    MOV             EAX, lastDigitScanned
    JMP             _checkLeadingZeros

; ---------------------------------------------------------------------------
; STEP 7: Store error code (or none) to be returned to caller.
; ---------------------------------------------------------------------------
; --------------------------------------------------  
; _invalidInput:
;     Store error code for invalid input.
; --------------------------------------------------  
_invalidInput:
    MOV             EDI, [EBP + 8]                          ; EDI = &errorCode
    MOV             EAX, 98
    MOV             [EDI], EAX                              ; *errorCode = 98 
    MOV             result, 0
    JMP             _storeResult

; --------------------------------------------------  
; _overflow:
;     Store error code for integer overflow.
; --------------------------------------------------  
_overflow:
    MOV             EDI, [EBP + 8]                          ; EDI = &errorCode
    MOV             EAX, 97
    MOV             [EDI], EAX                              ; *errorCode = 97 
    MOV             result, 0
    JMP             _storeResult

; --------------------------------------------------  
; _clearErrorCode:
;     No errors were produced, so clear error code.
; --------------------------------------------------  
_clearErrorCode:
    MOV             EDI, [EBP + 8]                          ; EDI = &errorCode
    MOV             EAX, 0
    MOV             [EDI], EAX                              ; *errorCode = 0

; --------------------------------------------------  
; _storeResult:
;     Store converted input (or none if error thrown).
; --------------------------------------------------  
_storeResult:
    MOV             EDI, [EBP + 12]                         ; EDI = &output
    MOV             EAX, result
    MOV             [EDI], EAX                              ; *output = result
    CLD

    POP             EDI
    POP             ESI
    POP             EDX
    POP             ECX
    POP             EBX
    POP             EAX
    RET             16
ASCIIToInt ENDP

; ---------------------------------------------------------------------------------------------------- 
; Name: intToASCII 
; 
; Converts a signed DWORD integer into a null-terminated ASCII string.
;
; Receives:
;     [EBP + 12]            = input
;                                 Value of signed integer to convert.
;     [EBP + 8]             = &result[]
;                                 Address to store result in.
;
; Local Variables:
;     digits[]              = byte array to temporarily store converted digit string
;     sign                  = store ASCII character for sign if it is negative
;     len                   = track converted digit string's length
;
; Returns:
;     *result[]             = str(input)
; ---------------------------------------------------------------------------------------------------- 
intToASCII PROC
    LOCAL           digits[12]:BYTE, sign:BYTE, len:DWORD
    PUSH            EAX
    PUSH            EBX
    PUSH            ECX
    PUSH            EDX
    PUSH            ESI
    PUSH            EDI

; ---------------------------------------------------------------------------
; STEP 1: Initialize local variables. 
; ---------------------------------------------------------------------------
    MOV             sign, 0h 
    MOV             len, 0

; ---------------------------------------------------------------------------
; STEP 2: Add null-terminator to digits string. 
; ---------------------------------------------------------------------------
    LEA             EDI, digits
    CLD
    XOR             EAX, EAX
    STOSB
    INC             len

; ---------------------------------------------------------------------------
; STEP 3: Check input sign and store it in digits string if it is negative. 
;
;         If input was negative, convert it to positive.
; ---------------------------------------------------------------------------
    MOV             EAX, [EBP + 12]                         ; EAX = input
    TEST            EAX, EAX                                ; if (input >= 0):
    JNS             _checkIfZero                            ;     goto _checkIfZero

    ; convert input to positive 
    MOV             EAX, [EBP + 12]                         ; EAX = input
    MOV             EBX, -1
    IMUL            EBX                                     ; EAX = input * -1
    MOV             sign, '-'

; ---------------------------------------------------------------------------
; STEP 4: Convert integer to a string. 
; ---------------------------------------------------------------------------
; --------------------------------------------------  
; _checkIfZero:
;     Check for special condition when input == 0.
; --------------------------------------------------  
_checkIfZero:
    TEST            EAX, EAX                                ; if (input == 0):
    JZ              _zero                                   ;     goto _zero

; --------------------------------------------------  
; _convertToString:
;     Convert integer to its ASCII representation. 
;
;     Stop once quotient is equal to zero.
; --------------------------------------------------  
    MOV             EBX, 10
_convertToString:
    TEST            EAX, EAX                                ; if (EAX == 0):                        
    JZ              _checkSign                              ;     goto _checkSign

    ; convert digit to ASCII
    XOR             EDX, EDX
    DIV             EBX                                     ; EAX = floor(input / 10)
    PUSH            EAX
    MOV             EAX, EDX
    ADD             EAX, 30h                                ; EAX = floor(input / 10) + '0'
    STOSB                                                   ; *digits[offset] = floor(input / 10) + '0'; offset++
    POP             EAX

    INC             len
    JMP             _convertToString

; --------------------------------------------------  
; _zero:
;     Handle special case for when input == 0. 
; --------------------------------------------------  
_zero:
    MOV             EAX, 30h
    STOSB
    INC             len
    JMP             _copyStr

; --------------------------------------------------  
; _checkSign:
;     Add '-' character to beginning of string if
;     input was negative.
; --------------------------------------------------  
_checkSign:
    MOVZX           EAX, sign
    TEST            EAX, EAX                                ; if (sign == 0h):
    JZ              _copyStr                                ;     goto _copyStr
    STOSB                                                   ; else: *digits[offset] = '-'
    INC             len

; --------------------------------------------------  
; _copyStr:
;     Copy over digits string to result.
;
;     Converted digits are in reverse order in 
;     digits string, so loop through it in reverse.
; --------------------------------------------------  
_copyStr:
    LEA             ESI, digits
    ADD             ESI, len 
    DEC             ESI                                     ; ESI = &digits[len - 1]
    MOV             EDI, [EBP + 8]                          ; EDI = &result[]

    MOV             ECX, len

; --------------------------------------------------  
; _copyDigit:
;     Copy a single digit from digits string to
;     result.
; --------------------------------------------------  
_copyDigit:
    STD
    LODSB                                                   ; EAX = *digits[inOffset]; inOffset--
    CLD
    STOSB                                                   ; *result[outOffset] = *digits[inOffset]; outOffset++
    LOOP            _copyDigit

    POP             EDI
    POP             ESI
    POP             EDX
    POP             ECX
    POP             EBX
    POP             EAX
    RET             8
intToASCII ENDP

; ---------------------------------------------------------------------------------------------------- 
; Name: pow32
;
; Returns the result of a ^ b.
;
; Preconditions:
;     1. a, b, and *result are DWORDs.
;
; Receives:
;     [EBP + 16]            = a
;                                 The base.
;     [EBP + 12]            = b
;                                 The exponent.
;     [EBP + 8]             = &result
;                                 Address to store result in.
;
; Returns:
;     *result               = a ^ b
; ---------------------------------------------------------------------------------------------------- 
pow32 PROC
    PUSH            EBP
    MOV             EBP, ESP
    PUSH            EAX
    PUSH            EBX
    PUSH            ECX
    PUSH            EDX
    PUSH            EDI

    MOV             EAX, [EBP + 16]                         ; EAX = a 
    MOV             ECX, [EBP + 12]                         ; ECX = b

; ---------------------------------------------------------------------------
; STEP 1: Check for special power conditions for when b == 0 or b == 1.
; ---------------------------------------------------------------------------
    TEST            ECX, ECX                                ; if (b == 0):
    JZ              _zeroPow                                ;     goto _zeroPow
    CMP             ECX, 1                                  ; elif (b == 1):
    JE              _storeResult                            ;     goto _storeResult

; ---------------------------------------------------------------------------
; STEP 2: Compute a ^ b. 
; ---------------------------------------------------------------------------
; -------------------------------------------------- 
; _powLoop:
;     Repeatedly multiply a by itself b times.
; -------------------------------------------------- 
    MOV             EBX, EAX                                ; EBX = a
    DEC             ECX
_powLoop:
    MUL             EBX                                     ; EAX *= a
    LOOP            _powLoop

    JMP             _storeResult

; -------------------------------------------------- 
; _zeroPow:
;     If b == 0, then the result is 1.
; -------------------------------------------------- 
_zeroPow:
    MOV             EAX, 1
    JMP             _storeResult

; -------------------------------------------------- 
; _storeResult:
;     Store answer to result.
; -------------------------------------------------- 
_storeResult:
    MOV             EDI, [EBP + 8]                          ; EDI = &result
    MOV             [EDI], EAX                              ; *result = a if b == 1, 1 if b == 0, else a^b 

    POP             EDI
    POP             EDX
    POP             ECX
    POP             EBX
    POP             EAX
    MOV             ESP, EBP
    POP             EBP
    RET             12
pow32 ENDP

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
