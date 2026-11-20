section .data
    prompt db 'Enter a number: ', 0
    heading db 'Binary: ', 0
    invalid db 'Enter a number', 10, 0
    invalid_number db 'Invalid number. Enter again: ', 0

section .bss
    binary resb 18
    input_char resb 1
    bad_input resb 1

section .text
    global _start

_start:
    mov ecx, prompt
    call print
    call read_int

    cmp eax, 65535
    jbe .convert

    mov ecx, invalid
    call print
    jmp _start

.convert:
    mov ebx, 2
    xor ecx, ecx

.divide:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz .divide

    mov edi, binary

.build:
    pop eax
    add al, '0'
    mov [edi], al
    inc edi
    loop .build

    mov byte [edi], 10
    mov byte [edi + 1], 0

    mov ecx, heading
    call print
    mov ecx, binary
    call print
    jmp exit_program

print:
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

read_int:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp

.retry:
    xor esi, esi
    xor edi, edi
    xor ebp, ebp
    mov byte [bad_input], 0

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80

    test eax, eax
    jle .eof
    movzx eax, byte [input_char]

    cmp al, 13
    je .read
    cmp al, 10
    je .finish

    cmp byte [bad_input], 0
    jne .read

    cmp al, '-'
    jne .digit
    test ebp, ebp
    jnz .bad
    mov edi, 1
    inc ebp
    jmp .read

.digit:
    sub eax, '0'
    cmp eax, 9
    ja .bad

    inc ebp
    imul esi, esi, 10
    jo .bad
    sub esi, eax
    jo .bad
    jmp .read

.bad:
    mov byte [bad_input], 1
    jmp .read

.eof:
    test ebp, ebp
    jz exit_program

.finish:
    cmp byte [bad_input], 0
    jne .invalid
    test ebp, ebp
    jz .invalid

    mov eax, esi
    test edi, edi
    jz .positive
    cmp ebp, 1
    je .invalid
    jmp .return

.positive:
    neg eax
    jo .invalid

.return:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.invalid:
    mov ecx, invalid_number
    call print
    jmp .retry

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80