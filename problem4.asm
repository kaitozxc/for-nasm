bits 32

section .data
    name_prompt db "Enter account name: ", 0
    pin_prompt db "Enter PIN: ", 0
    amount_prompt db "Enter withdrawal amount: ", 0

    granted db "ACCESS GRANTED", 10, 0
    denied db "ACCESS DENIED", 10, 0
    balance_label db "Current Balance: PHP ", 0

    invalid_amount db "INVALID AMOUNT", 10, 0
    insufficient db "INSUFFICIENT FUNDS", 10, 0
    not_multiple db "AMOUNT MUST BE A MULTIPLE OF 100", 10, 0

    success db "WITHDRAWAL SUCCESSFUL", 10, 0
    withdrawn_label db "Amount Withdrawn: PHP ", 0
    remaining_label db "Remaining Balance: PHP ", 0

    balance dd 10000
    input_error db "INVALID INPUT", 10, 0
    newline db 10, 0

section .bss
    account_name resb 128
    pin_text resb 128
    amount_text resb 128
    amount resd 1
    input_char resb 1
    number_text resb 12

section .text
    global _start

_start:
    ; Ask for account name.
    mov ecx, name_prompt
    call print_string

    mov ecx, account_name
    mov edx, 128
    call read_line
    jc bad_input

    ; Ask for PIN.
    mov ecx, pin_prompt
    call print_string

    mov ecx, pin_text
    mov edx, 128
    call read_line
    jc access_denied

    ; Require exactly four digits.
    cmp eax, 4
    jne access_denied

    mov esi, pin_text
    call parse_uint
    jc access_denied

    cmp eax, 1234
    jne access_denied

    ; Display the balance only after successful authentication.
    mov ecx, granted
    call print_string

    mov ecx, balance_label
    call print_string

    mov eax, [balance]
    call print_uint

    mov ecx, newline
    call print_string

    ; Ask for withdrawal amount.
    mov ecx, amount_prompt
    call print_string

    mov ecx, amount_text
    mov edx, 128
    call read_line
    jc bad_amount

    mov esi, amount_text
    call parse_uint
    jc bad_amount

    ; Check 1: amount must be positive.
    test eax, eax
    jz bad_amount

    ; Check 2: amount must not exceed balance.
    cmp eax, [balance]
    ja insufficient_funds

    mov [amount], eax

    ; Check 3: amount must be divisible by 100.
    xor edx, edx
    mov ebx, 100
    div ebx

    test edx, edx
    jnz wrong_multiple

    ; Deduct only after all checks pass.
    mov eax, [amount]
    sub [balance], eax

    mov ecx, success
    call print_string

    mov ecx, withdrawn_label
    call print_string

    mov eax, [amount]
    call print_uint

    mov ecx, newline
    call print_string

    mov ecx, remaining_label
    call print_string

    mov eax, [balance]
    call print_uint

    mov ecx, newline
    call print_string
    jmp exit_program

access_denied:
    mov ecx, denied
    call print_string
    jmp exit_program

bad_amount:
    mov ecx, invalid_amount
    call print_string
    jmp exit_program

insufficient_funds:
    mov ecx, insufficient
    call print_string
    jmp exit_program

wrong_multiple:
    mov ecx, not_multiple
    call print_string
    jmp exit_program

; Print a zero-terminated string at ECX.
print_string:
    pushad
    xor edx, edx

.count:
    cmp byte [ecx + edx], 0
    je .write
    inc edx
    jmp .count

.write:
    mov eax, 4
    mov ebx, 1
    int 0x80
    popad
    ret

; Read a full line into ECX with capacity EDX.
; Return EAX = length, CF = 1 for invalid input.
read_line:
    pushad
    mov edi, ecx
    mov esi, edx
    dec esi
    xor ebp, ebp
    xor ebx, ebx

.read:
    push ebx
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80
    pop ebx

    cmp eax, 0
    je .done
    jl .read_error

    mov al, [input_char]
    cmp al, 10
    je .done

    test al, al
    jz .bad_char

    cmp ebx, esi
    jae .bad_char

    mov [edi + ebx], al
    inc ebx
    jmp .read

.bad_char:
    mov ebp, 1
    jmp .read

.read_error:
    mov ebp, 1

.done:
    test ebx, ebx
    jz .empty

    cmp byte [edi + ebx - 1], 13
    jne .terminate
    dec ebx

.empty:
    test ebx, ebx
    jnz .terminate
    mov ebp, 1

.terminate:
    mov byte [edi + ebx], 0
    mov [esp + 28], ebx

    test ebp, ebp
    jnz .invalid

    popad
    clc
    ret

.invalid:
    popad
    stc
    ret

; Convert decimal text at ESI into EAX.
; Accept values from 0 to 2147483647.
parse_uint:
    push ebx
    push edx
    push esi
    xor eax, eax

    cmp byte [esi], 0
    je .invalid

.digit:
    movzx edx, byte [esi]
    test edx, edx
    jz .valid

    cmp edx, '0'
    jb .invalid
    cmp edx, '9'
    ja .invalid
    sub edx, '0'

    cmp eax, 214748364
    ja .invalid
    jb .accumulate

    cmp edx, 7
    ja .invalid

.accumulate:
    imul eax, eax, 10
    add eax, edx
    inc esi
    jmp .digit

.valid:
    pop esi
    pop edx
    pop ebx
    clc
    ret

.invalid:
    pop esi
    pop edx
    pop ebx
    stc
    ret

; Print the integer in EAX.
print_uint:
    pushad
    mov edi, number_text + 11
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

bad_input:
    mov ecx, input_error
    call print_string

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80