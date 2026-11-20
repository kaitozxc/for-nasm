%macro print_text 2
    mov ecx, %1
    mov edx, %2
    call print_proc
%endmacro

%macro print_amount 1
    mov eax, %1
    call money_proc
%endmacro

%macro input_field 3
    print_text %1, %2
    mov ecx, %3
    call read_proc
%endmacro

section .data
    title db 10, "CERTIFICATE OF REGISTRATION", 10
          db "-------------------------------", 10
    titleLen equ $-title

    statusMsg db "Enrollment Status: "
    statusLen equ $-statusMsg

    studentMsg db "Student Number: "
    studentLen equ $-studentMsg

    nameMsg db "Name: "
    nameLen equ $-nameMsg

    phoneMsg db "Phone: "
    phoneLen equ $-phoneMsg

    zipMsg db "Zip Code: "
    zipLen equ $-zipMsg

    classMsg db "Classification: "
    classLen equ $-classMsg

    newline db 10

    solar db "Course    Title                                Section Units Days Time          Room", 10
          db "------------------------------------------------------------------------------------------", 10
          db "CS0021    INFORMATION MANAGEMENT (LEC)         TN24    2     T    16:00-18:40   Online", 10
          db "CS0021L   INFORMATION MANAGEMENT (LAB)         TN24    1     F    16:00-18:50   Online", 10
          db "CS0001    DISCRETE STRUCTURES 1                TN24    3     F    10:00-12:40   F710/F710", 10
          db "CS0003    COMPUTER SYSTEMS & ARCHITECTURE       TN24    2     F    10:00-12:40   Online", 10
          db "CS0003L   COMPUTER SYSTEMS & ARCHITECTURE LAB   TN24    1     TH   10:00-12:50   E610", 10
          db "CS0070    OBJECT ORIENTED PROGRAMMING           TN26    2     F    13:00-15:40   Online", 10
          db "CS0070L   OBJECT ORIENTED PROGRAMMING LAB       TN26    1     M    13:00-15:50   E609", 10
          db "GED0021   SPECIALIZED ENGLISH PROGRAM 2         TN24    3     S/W  11:00-12:50   F607/F607", 10
          db "GED0055   MATHEMATICAL ANALYSIS                 M553    3     S/W  09:00-10:50   F712/F712", 10
          db "GED0081   COLLEGE PHYSICS 1 LECTURE             TS21    2     T    10:00-12:40   Online", 10
          db "GED0081L  COLLEGE PHYSICS 1 LAB                 TS21    1     M    10:00-12:50   F1003", 10
          db "------------------------------------------------------------------------------------------", 10, 10
    solarLen equ $-solar

    prompt db "Enter total units (1-99): "
    promptLen equ $-prompt

    tuitionMsg db 10, "Tuition Fee: PHP "
    tuitionLen equ $-tuitionMsg

    fees db "Miscellaneous Fee: PHP 12305.00", 10
         db "ID Validation Fee: PHP 80.00", 10
         db "ITE Computer Lab Fees: PHP 12024.00", 10
         db "Science Lab Fee: PHP 4104.00", 10
    feesLen equ $-fees

    totalMsg db "TOTAL ASSESSMENT: PHP "
    totalLen equ $-totalMsg

    downMsg db 10, "Down Payment (40%): PHP "
    downLen equ $-downMsg

    midMsg db "Midterm (30%): PHP "
    midLen equ $-midMsg

    finalMsg db "Final (30%): PHP "
    finalLen equ $-finalMsg

    errorMsg db 10, "Invalid input. Enter units from 1 to 99.", 10
    errorLen equ $-errorMsg

section .bss
    enrollment resb 128
    studentNumber resb 128
    studentName resb 128
    phone resb 128
    zipCode resb 128
    classification resb 128

    input resb 128
    inputChar resb 1
    number resb 16

    units resd 1
    tuition resd 1
    total resd 1
    payment resd 1

section .text
    global _start

_start:
    print_text title, titleLen

    input_field statusMsg, statusLen, enrollment
    input_field studentMsg, studentLen, studentNumber
    input_field nameMsg, nameLen, studentName
    input_field phoneMsg, phoneLen, phone
    input_field zipMsg, zipLen, zipCode
    input_field classMsg, classLen, classification

    print_text newline, 1
    print_text solar, solarLen

    print_text prompt, promptLen
    call input_proc

    test eax, eax
    jz invalid

    mov [units], eax
    call compute_proc

    print_text tuitionMsg, tuitionLen
    print_amount [tuition]

    print_text fees, feesLen

    print_text totalMsg, totalLen
    print_amount [total]

    ; Down payment: 40%
    mov eax, [total]
    imul eax, 40
    xor edx, edx
    mov ebx, 100
    div ebx
    mov [payment], eax

    print_text downMsg, downLen
    print_amount [payment]

    mov eax, [total]
    imul eax, 30
    xor edx, edx
    mov ebx, 100
    div ebx
    mov [payment], eax

    print_text midMsg, midLen
    print_amount [payment]

    print_text finalMsg, finalLen
    print_amount [payment]

    jmp exit

invalid:
    print_text errorMsg, errorLen

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; Display text
print_proc:
    push ebx

    mov eax, 4
    mov ebx, 1
    int 0x80

    pop ebx
    ret
    
read_proc:
    mov edi, ecx
    xor esi, esi

.read:
    mov eax, 3
    mov ebx, 0
    mov ecx, inputChar
    mov edx, 1
    int 0x80

    cmp eax, 1
    jne .done

    mov al, [inputChar]

    cmp al, 10
    je .done

    cmp al, 13
    je .read

    cmp esi, 127
    jae .read

    mov [edi + esi], al
    inc esi
    jmp .read

.done:
    mov byte [edi + esi], 0
    ret

input_proc:
    mov ecx, input
    call read_proc

    mov esi, input
    xor eax, eax

.convert:
    movzx edx, byte [esi]

    test edx, edx
    jz .done

    cmp dl, '0'
    jb .bad

    cmp dl, '9'
    ja .bad

    sub edx, '0'
    imul eax, 10
    add eax, edx

    cmp eax, 99
    ja .bad

    inc esi
    jmp .convert

.done:
    ret

.bad:
    xor eax, eax
    ret

compute_proc:
    mov eax, [units]
    imul eax, 210800
    mov [tuition], eax

    add eax, 2851300
    mov [total], eax
    ret

money_proc:
    mov edi, number + 15
    mov byte [edi], 10
    mov ecx, 1
    mov ebx, 10
    xor esi, esi

.convert:
    xor edx, edx
    div ebx
    add dl, '0'

    dec edi
    mov [edi], dl
    inc ecx
    inc esi

    cmp esi, 2
    jne .check

    dec edi
    mov byte [edi], '.'
    inc ecx

.check:
    test eax, eax
    jnz .convert

    cmp esi, 3
    jb .convert

    mov edx, ecx
    mov ecx, edi
    call print_proc
    ret