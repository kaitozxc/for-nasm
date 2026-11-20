BITS 32

%macro display 1
    mov ecx, %1
    call print_text
%endmacro

section .data
    filename db 'receipt.txt', 0

    menu db 10
         db '========== GEORGETTE EATERY ==========', 10
         db 'A. Plain Rice           Php 5.00', 10
         db 'B. Java Rice            Php 10.00', 10
         db 'C. Fish                 Php 35.00', 10
         db 'D. Pork                 Php 50.00', 10
         db 'E. Vegetables           Php 20.00', 10
         db 'F. Saging con yelo      Php 60.00', 10
         db '=====================================', 10, 0

    prompt db 'Enter your order: ', 0
    ordered db 'You ordered: ', 0
    again db 'Do you want to order again? [Y/N]: ', 0
    invalid db 'Invalid choice. Try again.', 10, 0
    goodbye db 10, 'Thank you! Please come again!', 10, 10, 0
    error db 'Cannot access receipt.txt.', 10, 0

        header db 'GEORGETTE EATERY', 10
            db 'Receipt', 10, 10, 0

    footer db 10, 'Thank you! Come again!', 10, 0 0

    rice db 'Plain Rice                   Php 5.00', 10, 0
    java db 'Java Rice                   Php 10.00', 10, 0
    fish db 'Fish                        Php 35.00', 10, 0
    pork db 'Pork                        Php 50.00', 10, 0
    vegetables db 'Vegetables                  Php 20.00', 10, 0
    dessert db 'Saging con yelo             Php 60.00', 10, 0

    items dd rice, java, fish, pork, vegetables, dessert

section .bss
    file resd 1
    selected resd 1
    input resb 1
    buffer resb 256

section .text
    global _start

_start:
    mov eax, 5
    mov ebx, filename
    mov ecx, 577
    mov edx, 0o644
    int 0x80
    cmp eax, 0
    jl file_error
    mov [file], eax

    mov ecx, header
    call save_text

show_menu:
    display menu

choose:
    display prompt
    call read_choice

    cmp eax, -1
    je finish

    sub eax, 'A'
    cmp eax, 5
    ja wrong_order

    mov eax, [items + eax * 4]
    mov [selected], eax

    display ordered
    mov ecx, [selected]
    call print_text

    mov ecx, [selected]
    call save_text

ask_again:
    display again
    call read_choice

    cmp eax, 'Y'
    je show_menu
    cmp eax, 'N'
    je finish
    cmp eax, -1
    je finish

    display invalid
    jmp ask_again

wrong_order:
    display invalid
    jmp choose

finish:
    mov ecx, footer
    call save_text

    mov eax, 6
    mov ebx, [file]
    int 0x80

    display goodbye

    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    int 0x80
    cmp eax, 0
    jl file_error
    mov [file], eax

show_receipt:
    mov eax, 3
    mov ebx, [file]
    mov ecx, buffer
    mov edx, 256
    int 0x80

    cmp eax, 0
    jl file_error
    je close_file

    mov edx, eax
    mov eax, 4
    mov ebx, 1
    mov ecx, buffer
    int 0x80
    jmp show_receipt

close_file:
    mov eax, 6
    mov ebx, [file]
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80

print_text:
    call text_length
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

save_text:
    call text_length
    mov eax, 4
    mov ebx, [file]
    int 0x80
    cmp eax, edx
    jne file_error
    ret

text_length:
    xor edx, edx
.count:
    cmp byte [ecx + edx], 0
    je .done
    inc edx
    jmp .count
.done:
    ret

read_choice:
    xor esi, esi
    xor edi, edi
.read:
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 1
    int 0x80

    cmp eax, 0
    jle .end_input

    movzx eax, byte [input]
    cmp al, 10
    je .check
    cmp al, 13
    je .read

    cmp esi, 0
    jne .extra
    mov edi, eax
.extra:
    mov esi, 2
    cmp edi, eax
    jne .read
    cmp esi, 2
    jne .read
    jmp .consume

.consume:
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 1
    int 0x80
    cmp eax, 0
    jle .check
    cmp byte [input], 13
    je .consume
    cmp byte [input], 10
    je .valid
    xor edi, edi
    jmp .consume

.check:
    cmp esi, 0
    je .invalid
.valid:
    mov eax, edi
    and eax, 0xDF
    ret

.invalid:
    xor eax, eax
    ret

.end_input:
    mov eax, -1
    ret

file_error:
    display error
    mov eax, 1
    mov ebx, 1
    int 0x80