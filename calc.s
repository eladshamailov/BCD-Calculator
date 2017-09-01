section .rodata
     opStackLength equ 5 
    LC1: 
       DB "%s",10,0
    LC2: 
       DB "%s", 0  
    LC3: 
       DB "%d",10,0 
    calc DB ">>calc: ",0

    overflow:
        DB ">>Error: Operand Stack Overflow",10,0
    insufficientArgs:
        DB ">>Error: Insufficient Number of Arguments on Stack",10,0
    largeExponent:
        DB ">>Error: exponent too large",10,0

section .bss
     opStack : resd 5 
LC4:
	RESB	256

section .data
   
     bufP times 80 DB 0		;buf print
     flagD DD 0
     numberLength : DD 0
     CurrNumPointer DD 0
     an DD 0              	
     linkPointer: DD 0
     data DD 0
     Max_lineLen DD 80 
     opStackPointer: DD 0
     buf: times 80 DB 0 
     successfulOpCount DD 0
     currLink DD 0
     previousPointer DD 0
     carryBool : DB 0

   
%macro startFunc 0 
    push ebp             ; Save caller state
    mov ebp, esp
    sub esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state
%endmacro

%macro endFunc 0 
    add esp, 4      	; Restore caller state
    pop ebp             ; Restore caller state
    ret                 ; Back to caller
%endmacro

%macro saveValue 0 
    mov [ebp-4], eax    ; Save value
    popad                   ; Restore caller state
    mov eax , [ebp-4]    ; place returned value
%endmacro

%macro printLC 2 
    pushad
    push %1
    push %2
    call printf
    add  esp, 8
    popad 		    ; Restore caller state
%endmacro

%macro debugPrinter 2 
    pushad
    push %1
    push %2
    push dword [stderr]
    call fprintf
    add  esp, 12
    popad
%endmacro

%macro callm 0		     ;new malloc size 5
    pushad
    push dword 5
    call malloc
%endmacro

%macro printErr 2
    pushad
    push %1
    call printf
    add  esp, %2
    popad
%endmacro

section .text 
     align 16 
     global main 
     extern printf
     extern fprintf  
     extern fgets 
     extern free
     extern stdin
     extern stderr
     extern malloc 
main:
    startFunc
    mov ecx,dword [ebp+8]    ; get function argument #1
    mov eax,dword[ebp+12]   ; get function argument #2
    cmp ecx,1			;if one argument so there is no -d
    je noDebug
    jg checkIfDebug		;if more than one go to -d

checkIfDebug:
    jmp allowDebug

allowDebug:
    mov ebx,[eax+4]     ;gets the argument after ./calc
    add ebx,1           ;gets the second letter of ther argument
    mov dl,[ebx]        ;moves the second letter to dl
    cmp dl ,100d	;checks if the second letter is d
    jne noDebug         ;if not d so its not debug
    dec ebx	        ;go to the first letter
    mov dl , [ebx]      ;moves the first letter to dl to check if its -
    cmp dl ,45d	;checks if the first letter is -
    je debugOn	        ;go to debug mode

noDebug:
    call calcFunc
    saveValue
    endFunc
    jmp calcFunc

debugOn:
    mov dword [flagD],1  				;allow the debug
    jmp noDebug

calcFunc:
    startFunc
    mov dword [opStackPointer] , opStack

mainLoop: 
    call printCalc		;print calc:
    call getInput		;get user's input

continueMainLoop:
    push buf
    call calculateLength	;calculate the length of the string
    add esp , 4
    cmp byte [buf] ,0		;if the input is null ignore
    je mainLoop
    cmp byte [buf] , 'q'
    je quit
    cmp byte [buf] , '+'
    je handleAdd
    cmp byte [buf] , 'p'
    je handlePop
    cmp byte [buf] , 'd'
    je handleDuplicate
    cmp byte [buf] , 'l'
    je handleShiftLeft
    cmp byte [buf] , 'r'
    je handleShiftRight
    jmp isLengthBiggerThanOne	;check if the length is bigger than one

isLengthBiggerThanOne:			;checks if the length of the string bigger than one
    mov eax , buf			;moves buf to eax
    cmp dword [numberLength] , 1	;checks if the length of the string is bigger than 1
    jne checkNewLine			;if the length bigger than 1 we need to check for zeros and for enter
    mov [CurrNumPointer] , eax		;if not bigger than one , the current number pointer is eax
    jmp handleNumber




;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;handle shift left
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

handleShiftLeft:
    mov ecx , buf
    mov ebx , [opStackPointer]
    sub ebx , opStack
    cmp ebx , 4
    jg continueShiftLeft
    printErr dword insufficientArgs,4		;not enough arguments in the stack
    jmp mainLoop
continueShiftLeft:
    call shiftLeftFunc
    call incOpCount
    cmp dword [flagD] , 0
    je mainLoop

debugHandleShiftLeft:
    call popNumHelperFunc
    debugPrinter eax,LC1

restoreNumberShiftLeft:					; push the number again to the stack
    mov ecx,eax
    push ecx
    call calculateLength
    times 4 inc esp
    push ecx
    push dword [numberLength]	           ;push the length of the number
    call handleNumInputFunc
    add esp , 8
    jmp mainLoop

shiftLeftFunc:
    startFunc
    call popNumHelperFunc		;get k
    mov ecx, eax				;move k to ecx
    cmp dword [ecx],39h
    jle shiftLeftFuncLoop
    printErr dword largeExponent,4
    jmp mainLoop

shiftLeftFuncLoop:
    sub dword [ecx],30h
shiftLeftLoop:					;add n k times
    cmp dword [ecx],0
    je endShiftLeftLoop
    call duplicateFunc
    call addFunc
    sub dword [ecx],1
    jmp shiftLeftLoop

endShiftLeftLoop:
    saveValue
    endFunc

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;handle shift right
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

handleShiftRight:
    mov ecx , buf
    mov ebx , [opStackPointer]
    sub ebx , opStack
    cmp ebx , 4
    jg continueShiftLeft
    printErr dword insufficientArgs,4		;not enough arguments in the stack
    jmp mainLoop
    printErr dword largeExponent,4
    jmp mainLoop

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;removes zeros from the number
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

checkNewLine:
    cmp byte [eax] , 10 	;checks if its a newLine
    jne not_new_line

checkIfZero:
    mov eax,buf			;put the input to eax
    mov ecx,eax			;move eax to ecx for the loop
    jmp removeZeroLoop

not_new_line:
    cmp byte [eax] , 0 		;checks if its null
    jne number			;if its not null so its a number
    mov eax , buf		;put the input to eax
    mov ecx,eax			;move eax to ecx for the loop
    jmp removeZeroLoop	
   
number:
    add eax,1			;go to the next
    jmp checkIfZero		;checks if the next one is zero 
    
removeZeroLoop:			;remove zero from the string
    cmp byte [ecx] , 30h	;check if 0
    je removeZero
    mov [CurrNumPointer] , eax	;if there are no zeros, the current number pointer is eax
    jmp handleNumber		;no zeros left so handleNumber
removeZero:
    dec dword [numberLength]	;dec the length by one , because we removed zero
    add ecx,1			;add one to the pointer and go to the next
    mov eax,ecx			;move the value to eax
    jmp removeZeroLoop

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;handle numbers
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

handleNumber:
    mov eax , opStack		;calc the end offset of the operand stack
    mov ecx , opStackLength
    add eax , ecx
    add eax , ecx
    add eax , ecx
    add eax , ecx	      ;added 4 times to inc in bytes
    
    cmp eax , [opStackPointer]	; if eax is equal to the pointer so the stack is full
    je stackFull              ; if there is no room in the stack
    push dword [CurrNumPointer]		;push current num
    push dword [numberLength]		;push the length of the number
    call handleNumInputFunc
    add esp,8
    cmp dword [flagD] ,0	;checks if we need to debug
    jne debugHandleNumber
    jmp mainLoop		;if flagD is 0 so end the iter

stackFull:    
    printErr dword overflow,4
    cmp dword [flagD] ,0	;checks if we need to debug
    jne debugHandleNumber
    jmp mainLoop		;if flagD is 0 so end the iter

debugHandleNumber:
    debugPrinter buf,LC2
    jmp mainLoop	

getInput:			;gets input from the user
    pushad
    push    dword [stdin] ;read from stdin
    push    Max_lineLen   ;push the max length of the stack
    push    dword buf
    call    fgets
    add     esp , 12
    popad
    ret	

printCalc:				;prints the message <<calc:
    pushad
    push calc
    call printf
    add esp, 4
    popad
    ret
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;adds number function
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
handleAdd:
    mov ecx , buf
    mov ebx , [opStackPointer]
    sub ebx , opStack
    cmp ebx , 4
    jg continueToAdd
    printErr dword insufficientArgs,4		; not enough arguments in the stack
    jmp mainLoop

continueToAdd:
    call addFunc
    cmp dword [flagD] ,0			; check if we need to debug
    je dontDebugAdd
    jne debugAdd

debugAdd:
    call incOpCount				;inc the number of successful ops
    call popNumHelperFunc		; print the number
    xor ecx,ecx					; clean ecx
    mov ecx,eax					; move eax to ecx
    debugPrinter ecx,LC1			; print the numbe for the debug mode

restoreNumber:					; push the number again to the stack
    push ecx
    call calculateLength
    times 4 inc esp
    push ecx
    push dword [numberLength]	           ;push the length of the number
    call handleNumInputFunc
    add esp , 8
    jmp mainLoop

dontDebugAdd:
    call incOpCount				;inc the number of successful ops
    jmp mainLoop

addFunc:
    startFunc
    mov ecx , [opStackPointer]
    sub ecx ,4
    sub ecx ,4
    mov esi , [ecx]
    times 4 inc ecx
    mov ecx , [ecx] 
    callm					; malloc space

    mov [linkPointer],eax			; eax is now in the linkPointer
    add esp,4
    popad
                                             
    mov edx , [linkPointer]			;linkPointer is now in edx
    mov [previousPointer] , edx		;link pointer is now in previous pointer
    mov bl,0
    mov bl , [ecx+4]
    mov al,0
    mov al , [esi+4]
    add al , bl
    daa						;Decimal adjust AL after addition.
    jc handleCarry_1				; jump if there is carry
    mov bl,0
    mov byte[carryBool],bl			; if no carry 
    jmp continueAdd1

handleCarry_1:					;if there is a carry
    mov bl,1
    mov byte[carryBool],bl

continueAdd1:
    mov bl,0
    mov bl,al
    mov al,0
    mov esi , [esi]
    mov ecx , [ecx]
    mov eax ,[previousPointer]
    mov [eax+4] , bl
    mov dword [eax] , 0

addNewLink:

compareEcx:		;checks if ecx is zero
    cmp ecx , 0
    jne ecxNotZeroComapreEsi
    je ecxZeroCompareEsi

ecxNotZeroComapreEsi:
    cmp esi , 0		;checks if esi is zero
    je ecxNotZeroEsiZero
    jne EcxAndEsiNotZeros

ecxZeroCompareEsi:
    cmp esi , 0
    je esiZeroEcxZero
    jne ecxZeroEsiNotZero


EcxAndEsiNotZeros:			 ;if esi and ecx are not zeros
    callm
    call ecxEsiStartFunc
    times 4 inc esp
    popad
    mov bl,0
    mov bl , [ecx+4]
    mov al,0
    mov al , [esi+4]
    cmp byte [carryBool] ,0
    jne addCarryBeforedaa1
    add al , bl
    daa
    jmp handleAdd1
addCarryBeforedaa1:
    add al , [carryBool]
    add al , bl
    daa

handleAdd1:
    mov dl,0
    mov dl , al
    jc handleCarry_2
    mov byte[carryBool] , 0
    mov eax,0
    mov ecx , [ecx]
    mov eax , [previousPointer]
    mov esi , [esi]
    mov [eax+4] , dl
    jmp addNewLink

handleCarry_2:
    mov     byte[carryBool] , 1
    mov eax,0
    mov ecx , [ecx]
    mov eax , [previousPointer]
    mov esi , [esi]
    mov [eax+4] , dl
    jmp addNewLink

ecxZeroEsiNotZero:				;ecx zero esi not zero

    callm
    call ecxEsiStartFunc
    times 4 inc esp
    popad
    mov al,0
    mov al , [esi+4]
    cmp byte [carryBool] ,0
    jne addCarryBeforedaa2
    daa
    jmp ContinuteAdd3

addCarryBeforedaa2:
    add al,[carryBool]
    daa

ContinuteAdd3:
    mov bl,al
    jc handleCarry_3
    mov byte[carryBool] , 0
    mov  esi , [esi]
    mov eax , [previousPointer]
    mov [eax+4] , bl
    jmp addNewLink

handleCarry_3:
    mov byte[carryBool] , 1
    mov  esi , [esi]
    mov eax , [previousPointer]
    mov [eax+4] , bl
    jmp addNewLink


ecxNotZeroEsiZero:

    callm
    call ecxEsiStartFunc
    times 4 inc esp
    popad
    mov al,0
    mov al , [ecx+4]
    cmp byte [carryBool] ,0
    jne addCarryBeforedaa5
    daa
    jmp continueAdd5

addCarryBeforedaa5:
    add al , [carryBool]
    daa

continueAdd5:
    mov bl,0
    mov bl , al
    jc handleCarry5
    mov byte[carryBool] , 0
    mov eax,0
    mov eax, [previousPointer]
    mov ecx , [ecx]
    mov [eax+4] , bl
    jmp addNewLink


handleCarry5:
    mov byte[carryBool] , 1
    mov eax,0
    mov eax, [previousPointer]
    mov ecx , [ecx]
    mov [eax+4] , bl
    jmp addNewLink

esiZeroEcxZero:
    cmp byte [carryBool] ,1
    je carryNotZero
    cmp byte [carryBool] , 0
    jg carryNotZero
    jle carryZero

carryZero:

jmp removeNumbersFromStack
removeNumbersFromStack:
    call removeFromStack		;remove first number from the stack
    sub dword [opStackPointer] , 4
    call removeFromStack		;remove second number from the stack
    sub dword [opStackPointer] , 4
    mov edx,0
    jmp continueCarryZero

continueCarryZero:
    mov edx , [linkPointer]
    mov ebx,0
    mov ebx , [opStackPointer]
    mov [ebx], edx
    add dword [opStackPointer] , 4
    jmp endadd

carryNotZero:
    callm
    call ecxEsiStartFunc
    times 4 inc esp
    popad

    mov eax , [previousPointer]
    mov byte [eax+4] , 1		;add the carry
    jmp carryZero

endadd:
    saveValue
    endFunc

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;pop number function
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
handlePop:
    mov ecx , buf				;put the string to ecx
    cmp dword [opStackPointer] , opStack		;checks if there is enough arguments in the stack
    je notEnoughArguments					;if there is not enough arguments
    call popNumFunc					;there is enough arguments in the stack-print the number
    call incOpCount
    jmp mainLoop

notEnoughArguments:						;print error if there is not enoguh arguments
    printErr dword insufficientArgs,4
    jmp mainLoop

popNumFunc: 
b6:
    startFunc
    call popNumHelperFunc
    mov dword [data],0
    printLC eax,LC1
    popad                   ; Restore caller state
    endFunc

popNumHelperFunc:
    startFunc
    mov ebx ,[opStackPointer]
    sub ebx , 4
    mov eax , bufP +7 		;point last place before null pointer
    mov edx , [ebx]
    mov dword[previousPointer] , edx

numberToPrint:
    xor edx,edx
    mov edx , [previousPointer]
    times 4 inc edx 			;go to the next val
    mov ch , [edx]			;mov edx value to counter register   
    and ch , 00001111b			;retain only the rightmost 4 bits, clearing the left 4 bits
    add ch , 30h				;add the char 0
    mov [eax] , ch
    mov edx , [previousPointer]
    times 4 inc edx		;go to the next val
    mov ch , [edx]
    sub eax,1
    and ch , 11110000b   			;retain only the left 4 bits, clearing the right 4 bits
    shr ch, 4
    add ch , 30h				;add the char 0
    mov [eax] , ch
    mov edx , [previousPointer]
    mov ebx , [edx]
    sub eax,1
    cmp ebx , 0				;checks if its the end of the num
    jne continueLoop				;if not continue the loop
    je sendToPrint

sendToPrint:
    inc eax
    cmp byte [eax],30h		;checks if it's zero
    jne noZeroInNum
    inc eax
    jmp noZeroInNum

continueLoop:
    mov [previousPointer] , ebx     
    jmp numberToPrint

noZeroInNum:
    add eax,2
    sub eax,2
    call  removeFromStack
    sub dword [opStackPointer] , 4		;dec by one
    saveValue
    endFunc

incOpCount:
    inc dword [successfulOpCount]				;inc the succesful op counter
    ret

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;quit function
;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
quit:
    mov ecx , buf

printOpNum:				;print the number of successful ops
    printLC dword [successfulOpCount],dword LC3
    popad                   ; Restore caller state
    endFunc

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;calculate the length of the string
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
calculateLength:

    startFunc
    mov ebx , [ebp+8]  ; put the string to ebx
    mov dword [numberLength] , 0	;set the counter to 0
countLengthLoop:
    cmp byte [ebx] , 0	;checks if its the end of the string
    je  endCount
    cmp byte [ebx] , 10	;checks if its a newLine
    je  endCount
    inc dword [numberLength]		;increase the counter
    inc ebx					;inc the pointer and go to the next char
    jmp countLengthLoop

endCount:
    mov [ebp-4], eax    ; Save returned value
    popad                   ; Restore caller state
    endFunc

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;duplicate number function
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
not_empty:
printErr dword overflow,4
    jmp mainLoop

notEmptyStack:
    call duplicateFunc
    call incOpCount
    cmp dword [flagD] , 0
    je mainLoop

debugDuplicate:
    call popNumHelperFunc
    debugPrinter eax,LC1
    push eax
    call calculateLength
    add esp , 4
    push eax
    push dword [numberLength]	               ;push the length of the number
    call handleNumInputFunc
    add esp , 8
    jmp mainLoop

handleDuplicate:
    mov ebx , [opStackPointer]
    mov eax, opStack
    sub ebx, eax
    mov ecx , opStackLength
    shl ecx , 2
    cmp ebx , ecx
    jge not_empty
 
    cmp ebx , 0
    jg  notEmptyStack
    printErr dword insufficientArgs,4
    jmp mainLoop
     

duplicateFunc:
    
    startFunc
    mov ecx , [opStackPointer]
    times 4 dec ecx
    mov ecx , [ecx]
    callm
    mov [linkPointer] , eax
    times 4 inc esp
    popad
    jmp continueDuplicateFunc

duplicateLoop:
    cmp ecx , 0
    jne continueDuplicateLoop
    mov edx ,[linkPointer]		;if the duplicate link completed
    mov ebx ,[opStackPointer]
    mov [ebx], edx
    add dword [opStackPointer] , 4
    saveValue
    endFunc

continueDuplicateLoop:
    callm
    call ecxEsiStartFunc 			;function from add , move previousPointer to edx and previousPointer becomes eax
    times 4 inc esp
    popad
    mov eax,0
    mov eax,[previousPointer]
    mov bl,0
    mov bl , [ecx+4]
    mov [eax+4] , bl
    mov ecx , [ecx]
    jmp duplicateLoop

continueDuplicateFunc:
    mov edx,[linkPointer]
    mov eax,0
    mov [previousPointer] , edx
    mov eax , [previousPointer]
    mov bl , [ecx+4]
    mov ecx , [ecx]
    mov [eax+4] , bl
    mov dword [eax] , 0
    cmp dword [eax],0
    je duplicateLoop

ecxEsiStartFunc:
    mov edx , [previousPointer]  
    mov [edx] , eax
    mov dword [eax] , 0
    mov [previousPointer] , eax
    ret
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


handleNumInputFunc:

    startFunc
    call moveValue	       ;move the pointer to ecx and add the length
    sub ecx,1 
    callm	               ; new malloc size 5
    mov [linkPointer] , eax
    times 4 inc  esp
    popad

    mov edx , [linkPointer]			;the link is edx
    mov [previousPointer] , edx		;the previous pointer is now the previous link
    mov dl , [ecx]

bd:
    sub dl , 30h	   ;sub char zero to get to decimal value of the digit
    dec dword [ebp+8]      ; dec the length of the number
    cmp dword [ebp+8] , 0  ; check if the length is zero
    jg notOneDigit          ;if the length is zero so there was single digit

oneDigit:
    mov eax,[previousPointer]		;make previousPointer to point the current
    mov [eax+4] , dl		        ;dl is storded in the new link
    mov dword [eax] , 0			;eax pointing to null
    dec dword [ebp+8]      		; dec the length of the number   
    jmp endInputFunc

notOneDigit:
    dec ecx
    mov al,0
    mov al , byte [ecx]   
    call makeLeftNum       ;there is more than one digit , so make the digit be the left one (as *10 in decimal) 
    mov bl,0
    mov bl,al
    add bl, dl
    inc bl
    mov eax,0
    mov eax , [previousPointer]
    dec bl
    mov [eax+4] , bl
    mov dword [eax] , 0
    dec dword [ebp+8]     ; dec the length of the number
    mov dword [eax] , 0   
    jmp endInputFunc

endInputFunc:
newLinkLoop:
    call moveValue
    sub ecx,1
    cmp dword  [ebp+8] , 0      ; check if the length is zero
    jg linkNotCompleted
    jle createLinkCompleted

linkNotCompleted:

    callm
    mov edx,0
    mov edx , [previousPointer]  
    jmp continueLink1

continueLink1:
    mov [edx] , eax
    mov dword [eax] , 0
    mov [previousPointer] , eax
    times 4 inc esp
    popad
    jmp continueLink2

continueLink2:
    mov dl,0
    mov dl , [ecx]
    sub dl , 30h
    dec dword [ebp+8]      ; dec the length of the number
    cmp  dword [ebp+8] , 0  ; check if the length is zero
    jne notLastDigit

lastDigit:
    mov eax,0
    mov eax , [previousPointer]
    mov [eax+4] , dl
    dec dword [ebp+8]      ; dec the length of the number   
    jmp newLinkLoop

notLastDigit:          
    dec ecx
    mov bl , [ecx]
    shl bl,4		
    shr bl,4
    sub bl, 30h
    shl bl , 4
    add bl , dl
    mov eax , [previousPointer]
    mov [eax+4] , bl

    dec dword [ebp+8]      ; dec the length of the number  
    jmp newLinkLoop

createLinkCompleted:
    mov edx,0
    mov edx , [linkPointer]
    mov ebx ,  [opStackPointer]
    mov [ebx], edx
    add dword [opStackPointer] , 4
    saveValue
    endFunc

moveValue:		 ;move the pointer to ecx an add the length
    mov ecx , [ebp+12]     ;    move the current numPointer to ecx
    add ecx , [ebp+8]    ;    add the length of the number to ecx
    ret   

makeLeftNum:		; the digit will be the left one (as *10 in decimal)
    mov bl,16
    mul bl
    ret

removeFromStack:

   startFunc
    mov ebx , [opStackPointer]
    times 4 dec ebx
    mov ebx , [ebx]
    jmp keep_free

free_loop:
    pushad
    push dword [currLink]
    call free
    times 4 inc esp
    popad
    cmp ebx , 0
    jg keep_free
    mov     [ebp-4], eax    ; Save value
    popad                   ; Restore caller state
    endFunc

keep_free:   
    mov [currLink] , ebx
    mov ebx , [ebx]
    jmp free_loop 

