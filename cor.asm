%macro print_text 2
    mov ecx, %1
    mov edx, %2
    call print_proc
%endmacro

%macro get_input 3
%%again:
    print_text %1, %2
    mov ecx, %3
    call read_proc
    cmp eax, -1
    je exit
    cmp eax, -2
    jne %%done
    print_text longMsg, longLen
    jmp %%again
%%done:
%endmacro

%macro append_text 2
    mov ecx, %1
    mov edx, %2
    call append_proc
%endmacro

%macro append_field 3
    append_text %1, %2
    mov ecx, %3
    call append_string
    append_text newline, 1
%endmacro

%macro print_amount 1
    mov eax, %1
    call money_proc
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

    menu db 10, "===============================", 10
         db "              COR", 10
         db "===============================", 10
         db "1. Input - Enter details and total units", 10
         db "2. Output - Display full information", 10
         db "3. Write - Save full details to a file", 10
         db "4. Read - Display the saved file", 10
         db "5. Exit", 10
         db "Enter your choice: "
    menuLen equ $-menu

    filename db "cor_record.txt", 0

    unitsLabel db "Total Units: "
    unitsLabelLen equ $-unitsLabel

    enteredMsg db 10, "Details entered successfully.", 10
    enteredLen equ $-enteredMsg

    noDataMsg db 10, "Choose 1 and enter your details first.", 10
    noDataLen equ $-noDataMsg

    savedMsg db 10, "Full COR saved to cor_record.txt.", 10
    savedLen equ $-savedMsg

    fileErrorMsg db 10, "Could not open, read, or write cor_record.txt.", 10
    fileErrorLen equ $-fileErrorMsg

    choiceMsg db 10, "Invalid choice. Enter a number from 1 to 5.", 10
    choiceLen equ $-choiceMsg

    longMsg db 10, "Input is too long. Use up to 127 characters.", 10
    longLen equ $-longMsg

section .bss
    enrollment resb 128
    studentNumber resb 128
    studentName resb 128
    phone resb 128
    zipCode resb 128
    classification resb 128
    unitsText resb 128
    input resb 128
    inputChar resb 1
    overflow resb 1
    number resb 16
    units resd 1
    tuition resd 1
    total resd 1
    payment resd 1
    hasData resb 1
    report resb 8192
    reportLen resd 1
    fileHandle resd 1
    fileBuffer resb 1024

section .text
    global _start

_start:
    cld

main_menu:
    print_text menu, menuLen
    mov ecx, input
    call input_proc

    cmp eax, 1
    je input_action
    cmp eax, 2
    je output_action
    cmp eax, 3
    je write_action
    cmp eax, 4
    je read_action
    cmp eax, 5
    je exit

    print_text choiceMsg, choiceLen
    jmp main_menu

input_action:
    get_input statusMsg, statusLen, enrollment
    get_input studentMsg, studentLen, studentNumber
    get_input nameMsg, nameLen, studentName
    get_input phoneMsg, phoneLen, phone
    get_input zipMsg, zipLen, zipCode

.units_again:
    print_text prompt, promptLen
    mov ecx, unitsText
    call input_proc
    test eax, eax
    jnz .valid
    print_text errorMsg, errorLen
    jmp .units_again

.valid:
    mov [units], eax
    call compute_proc
    call build_report
    mov byte [hasData], 1
    print_text enteredMsg, enteredLen
    jmp main_menu

output_action:
    cmp byte [hasData], 1
    jne no_data
    print_text report, [reportLen]
    jmp main_menu

write_action:
    cmp byte [hasData], 1
    jne no_data

    mov eax, 5
    mov ebx, filename
    mov ecx, 577
    mov edx, 420
    int 0x80

    test eax, eax
    js file_error

    mov [fileHandle], eax
    mov esi, report
    mov edi, [reportLen]

.write_loop:
    mov eax, 4
    mov ebx, [fileHandle]
    mov ecx, esi
    mov edx, edi
    int 0x80

    test eax, eax
    jle .failed

    add esi, eax
    sub edi, eax
    jnz .write_loop

    mov eax, 6
    mov ebx, [fileHandle]
    int 0x80

    test eax, eax
    js file_error

    print_text savedMsg, savedLen
    jmp main_menu

.failed:
    mov eax, 6
    mov ebx, [fileHandle]
    int 0x80
    jmp file_error

read_action:
    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    int 0x80

    test eax, eax
    js file_error

    mov [fileHandle], eax
    print_text newline, 1

.read_loop:
    mov eax, 3
    mov ebx, [fileHandle]
    mov ecx, fileBuffer
    mov edx, 1024
    int 0x80

    test eax, eax
    js .failed
    jz .done

    print_text fileBuffer, eax
    jmp .read_loop

.done:
    mov eax, 6
    mov ebx, [fileHandle]
    int 0x80

    test eax, eax
    js file_error

    jmp main_menu

.failed:
    mov eax, 6
    mov ebx, [fileHandle]
    int 0x80
    jmp file_error

no_data:
    print_text noDataMsg, noDataLen
    jmp main_menu

file_error:
    print_text fileErrorMsg, fileErrorLen
    jmp main_menu

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

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
    mov byte [overflow], 0

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, inputChar
    mov edx, 1
    int 0x80

    test eax, eax
    js .unavailable
    jz .eof

    mov al, [inputChar]
    cmp al, 10
    je .done
    cmp al, 13
    je .read
    cmp esi, 127
    jae .too_long

    mov [edi + esi], al
    inc esi
    jmp .read

.too_long:
    mov byte [overflow], 1
    jmp .read

.eof:
    test esi, esi
    jnz .done

.unavailable:
    mov byte [edi + esi], 0
    mov eax, -1
    ret

.done:
    mov byte [edi + esi], 0
    mov eax, esi
    cmp byte [overflow], 0
    je .return
    mov eax, -2

.return:
    ret

input_proc:
    push ecx
    call read_proc
    pop esi

    cmp eax, -1
    je exit
    cmp eax, 0
    jle .bad

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

build_report:
    mov dword [reportLen], 0

    append_text title, titleLen
    append_field statusMsg, statusLen, enrollment
    append_field studentMsg, studentLen, studentNumber
    append_field nameMsg, nameLen, studentName
    append_field phoneMsg, phoneLen, phone
    append_field zipMsg, zipLen, zipCode
    append_field classMsg, classLen, classification
    append_text newline, 1
    append_text solar, solarLen
    append_field unitsLabel, unitsLabelLen, unitsText

    append_text tuitionMsg, tuitionLen
    print_amount [tuition]
    append_text fees, feesLen
    append_text totalMsg, totalLen
    print_amount [total]

    mov eax, [total]
    imul eax, 40
    xor edx, edx
    mov ebx, 100
    div ebx
    mov [payment], eax

    append_text downMsg, downLen
    print_amount [payment]

    mov eax, [total]
    imul eax, 30
    xor edx, edx
    mov ebx, 100
    div ebx
    mov [payment], eax

    append_text midMsg, midLen
    print_amount [payment]
    append_text finalMsg, finalLen
    print_amount [payment]
    ret

append_string:
    xor edx, edx

.count:
    cmp byte [ecx + edx], 0
    je .append
    inc edx
    jmp .count

.append:
    call append_proc
    ret

append_proc:
    pushad
    mov edi, report
    add edi, [reportLen]
    mov esi, ecx
    mov ecx, edx
    rep movsb
    add [reportLen], edx
    popad
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
    call append_proc
    ret