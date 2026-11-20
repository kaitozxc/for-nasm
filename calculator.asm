; calculator.asm — NASM32, Linux

section .data
    clear db 27, "[2J", 27, "[H"
    clearLen equ $ - clear
    menu db "MENU", 10, "[A]dd", 10, "[S]ubtract", 10
         db "[M]ultiply", 10, "[D]ivide", 10, "Enter your choice: "
    menuLen equ $ - menu
    first db "Enter first number: "
    firstLen equ $ - first
    second db "Enter second number: "
    secondLen equ $ - second
    again db "Do you want to try again (Y/N): "
    againLen equ $ - again
    resultMsg db "The result is "
    resultLen equ $ - resultMsg
    newline db 10

section .bss
    input resb 32
    output resb 16
    choice resb 2
    num1 resd 1
    num2 resd 1
    answer resd 1
    operation resb 1

section .text
    global _start

_start:
menu_loop:
    mov eax, 4
    mov ebx, 1
    mov ecx, clear
    mov edx, clearLen
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, menu
    mov edx, menuLen
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 0x80

    mov al, [choice]
    cmp al, 'A'
    je get_numbers
    cmp al, 'a'
    je get_numbers
    cmp al, 'S'
    je get_numbers
    cmp al, 's'
    je get_numbers
    cmp al, 'M'
    je get_numbers
    cmp al, 'm'
    je get_numbers
    cmp al, 'D'
    je get_numbers
    cmp al, 'd'
    jne menu_loop

get_numbers:
    mov [operation], al

    mov eax, 4
    mov ebx, 1
    mov ecx, first
    mov edx, firstLen
    int 0x80
    call read_int
    mov [num1], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, second
    mov edx, secondLen
    int 0x80
    call read_int
    mov [num2], eax

    mov eax, [num1]
    mov ebx, [num2]
    mov cl, [operation]

    cmp cl, 'A'
    je add_nums
    cmp cl, 'a'
    je add_nums
    cmp cl, 'S'
    je subtract_nums
    cmp cl, 's'
    je subtract_nums
    cmp cl, 'M'
    je multiply_nums
    cmp cl, 'm'
    je multiply_nums

    cmp ebx, 0
    je menu_loop
    xor edx, edx
    div ebx
    jmp show_result

add_nums:
    add eax, ebx
    jmp show_result

subtract_nums:
    sub eax, ebx
    jmp show_result

multiply_nums:
    mul ebx

show_result:
    mov [answer], eax
    mov eax, 4
    mov ebx, 1
    mov ecx, resultMsg
    mov edx, resultLen
    int 0x80

    mov eax, [answer]
    call print_int

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, again
    mov edx, againLen
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 0x80

    mov al, [choice]
    cmp al, 'Y'
    je menu_loop
    cmp al, 'y'
    je menu_loop

    mov eax, 1
    xor ebx, ebx
    int 0x80

; Reads a line and converts its digits to an integer.
read_int:
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 32
    int 0x80

    xor eax, eax
    mov esi, input
.read:
    mov bl, [esi]
    cmp bl, 10
    je .done
    cmp bl, 13
    je .done
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    imul eax, eax, 10
    sub bl, '0'
    movzx ebx, bl
    add eax, ebx
    inc esi
    jmp .read
.done:
    ret

; Prints the signed integer in EAX.
print_int:
    mov edi, output + 15
    mov byte [edi], 10
    mov ebx, 10
    xor esi, esi
    test eax, eax
    jns .digits
    neg eax
    mov esi, 1
.digits:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .digits
    test esi, esi
    jz .write
    dec edi
    mov byte [edi], '-'
.write:
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    mov edx, output + 16
    sub edx, edi
    int 0x80
    ret