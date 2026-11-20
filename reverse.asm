section .data
    prompt db 'Enter a word: ', 0
    heading db 'Reversed: ', 0
    too_long db 'String too long. Try again.', 10, 0
    newline db 10, 0

section .bss
    text resb 128
    input_char resb 1
    input_overflow resb 1

section .text
    global _start

_start:
    mov ecx, prompt
    call print

    mov ecx, text
    mov edx, 128
    call read_line

    test eax, eax
    jns .reverse
    mov ecx, too_long
    call print
    jmp _start

.reverse:
    mov ecx, eax
    mov esi, text
    test ecx, ecx
    jz .display
    mov edx, ecx

.push:
    movzx eax, byte [esi]
    push eax
    inc esi
    loop .push

    mov ecx, edx
    mov edi, text

.pop:
    pop eax
    mov [edi], al
    inc edi
    loop .pop

.display:
    mov ecx, heading
    call print
    mov ecx, text
    call print
    mov ecx, newline
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

read_line:
    push ebx
    push esi
    push edi
    push ebp

    mov esi, ecx
    mov ebp, edx
    dec ebp
    xor edi, edi
    mov byte [input_overflow], 0

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80

    test eax, eax
    jle .eof
    mov al, [input_char]

    cmp al, 10
    je .done
    cmp al, 13
    je .read

    cmp edi, ebp
    jae .full
    mov [esi + edi], al
    inc edi
    jmp .read

.full:
    mov byte [input_overflow], 1
    jmp .read

.eof:
    test edi, edi
    jz exit_program

.done:
    mov byte [esi + edi], 0
    mov eax, edi
    cmp byte [input_overflow], 0
    je .return
    mov eax, -1

.return:
    pop ebp
    pop edi
    pop esi
    pop ebx
    ret

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80