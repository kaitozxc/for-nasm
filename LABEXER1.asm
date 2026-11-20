section .data
    clearText db 27, '[2J', 27, '[H', 0

    menuText db '----------------------------------', 10
             db 'MENU', 10
             db '[A]dd', 10
             db '[S]ubtract', 10
             db '[M]ultiply', 10
             db '[D]ivide', 10
             db '----------------------------------', 10
             db 'Enter your choice: ', 0

    firstPrompt  db 'Enter first number: ', 0
    secondPrompt db 'Enter second number: ', 0

    sumText        db 'The sum is ', 0
    differenceText db 'The difference is ', 0
    productText    db 'The product is ', 0
    quotientText   db 'The quotient is ', 0
    remainderText  db 'The remainder is ', 0

    againText db 10, 'Do you want to try again (Y/N): ', 0

    choiceError db 'Invalid choice. Enter A, S, M or D.', 10, 0
    numberError db 'Enter one or two digits only (0-99).', 10, 0
    againError  db 'Please enter Y or N.', 10, 0
    zeroError   db 'Cannot divide by zero.', 10, 0

    goodbyeText db 'Program terminated.', 10, 0
    eofText     db 10, 'Input ended. Program terminated.', 10, 0
    readError   db 10, 'Unable to read input.', 10, 0

    minusText db '-', 0
    newline   db 10, 0

section .bss
    choice       resb 1
    firstNumber  resd 1
    secondNumber resd 1

    inputBuffer  resb 3
    inputChar    resb 1
    outputBuffer resb 12

section .text
    global _start

_start:
.menu:
    call clear_screen

    mov ecx, menuText
    call print_string

.choice:
    call read_line

    cmp eax, 1
    jne .bad_choice

    mov al, [inputBuffer]
    and al, 0DFh

    cmp al, 'A'
    je .accepted
    cmp al, 'S'
    je .accepted
    cmp al, 'M'
    je .accepted
    cmp al, 'D'
    je .accepted

.bad_choice:
    mov ecx, choiceError
    call print_string

    mov ecx, menuText
    call print_string
    jmp .choice

.accepted:
    mov [choice], al

    mov ecx, firstPrompt
    call read_number
    mov [firstNumber], eax

    mov ecx, secondPrompt
    call read_number
    mov [secondNumber], eax

    cmp byte [choice], 'A'
    je .add

    cmp byte [choice], 'S'
    je .subtract

    cmp byte [choice], 'M'
    je .multiply

    call divide_numbers
    jmp .again

.add:
    call add_numbers
    jmp .again

.subtract:
    call subtract_numbers
    jmp .again

.multiply:
    call multiply_numbers

.again:
    mov ecx, againText
    call print_string
    call read_line

    cmp eax, 1
    jne .bad_again

    mov al, [inputBuffer]
    and al, 0DFh

    cmp al, 'Y'
    je .menu

    cmp al, 'N'
    je .quit

.bad_again:
    mov ecx, againError
    call print_string
    jmp .again

.quit:
    mov ecx, goodbyeText
    call print_string

    mov eax, 1
    xor ebx, ebx
    int 0x80

add_numbers:
    mov eax, [firstNumber]
    add eax, [secondNumber]

    mov ecx, sumText
    call show_result
    ret
    
subtract_numbers:
    mov eax, [firstNumber]
    sub eax, [secondNumber]

    mov ecx, differenceText
    call show_result
    ret

multiply_numbers:
    mov eax, [firstNumber]
    imul eax, [secondNumber]

    mov ecx, productText
    call show_result
    ret

divide_numbers:
    cmp dword [secondNumber], 0
    je .zero

    mov eax, [firstNumber]
    xor edx, edx
    div dword [secondNumber]

    push edx

    mov ecx, quotientText
    call show_result

    pop eax
    mov ecx, remainderText
    call show_result
    ret

.zero:
    mov ecx, zeroError
    call print_string
    ret

show_result:
    call print_string
    call print_number

    mov ecx, newline
    call print_string
    ret

clear_screen:
    mov ecx, clearText
    call print_string
    ret

print_string:
    pushad
    xor edx, edx

.length:
    cmp byte [ecx + edx], 0
    je .write

    inc edx
    jmp .length

.write:
    mov eax, 4
    mov ebx, 1
    int 0x80

    popad
    ret

read_line:
    push ebx
    push ecx
    push edx
    push esi
    push edi

    xor esi, esi
    xor edi, edi

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, inputChar
    mov edx, 1
    int 0x80

    cmp eax, -4 
    je .read

    test eax, eax
    jz input_ended
    js input_error

    mov al, [inputChar]

    cmp al, 10
    je .done

    cmp al, 13
    je .read

    cmp esi, 2
    jae .too_long

    mov [inputBuffer + esi], al
    inc esi
    jmp .read

.too_long:
    mov edi, 1
    jmp .read

.done:
    mov byte [inputBuffer + esi], 0
    mov eax, esi

    test edi, edi
    jz .return

    mov eax, -1

.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

read_number:
    push ebx
    push esi
    push edi

    mov esi, ecx

.retry:
    mov ecx, esi
    call print_string
    call read_line

    cmp eax, 1
    jl .invalid

    mov edi, eax
    xor ebx, ebx
    xor eax, eax

.digit:
    movzx edx, byte [inputBuffer + ebx]

    cmp edx, '0'
    jb .invalid
    cmp edx, '9'
    ja .invalid

    sub edx, '0'
    imul eax, eax, 10
    add eax, edx

    inc ebx
    cmp ebx, edi
    jb .digit

    pop edi
    pop esi
    pop ebx
    ret

.invalid:
    mov ecx, numberError
    call print_string
    jmp .retry

print_number:
    pushad

    test eax, eax
    jns .positive

    mov ecx, minusText
    call print_string
    neg eax

.positive:
    mov edi, outputBuffer + 11
    mov byte [edi], 0
    mov ebx, 10

.digit:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl

    test eax, eax
    jnz .digit

    mov ecx, edi
    call print_string

    popad
    ret

input_ended:
    mov ecx, eofText
    call print_string

    mov eax, 1
    xor ebx, ebx
    int 0x80

input_error:
    mov ecx, readError
    call print_string

    mov eax, 1
    mov ebx, 1
    int 0x80