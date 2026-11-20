section .data
    name_prompt db "What is your name? ", 0
    age_prompt db "How old are you? ", 0
    gender_prompt db "What is your gender? ", 0

    hello_name db "Hello ", 0
    age_prefix db "You are ", 0
    age_suffix db " years old", 10, 0

    male_message db "Hello", 10, 0
    female_message db "World", 10, 0
    invalid_gender db "INVALID", 10, 0
    age_error db "INVALID AGE", 10, 0
    input_error db "INVALID INPUT", 10, 0
    newline db 10, 0

section .bss
    full_name resb 128
    age_text resb 128
    age resd 1
    gender resb 128
    input_char resb 1
    number_text resb 12

section .text
    global _start

_start:
    mov ecx, name_prompt
    call print_string

    mov ecx, full_name
    mov edx, 128
    call read_line
    jc bad_input

    mov ecx, age_prompt
    call print_string

    mov ecx, age_text
    mov edx, 128
    call read_line
    jc bad_age

    mov esi, age_text
    call parse_uint
    jc bad_age
    mov [age], eax

    mov ecx, gender_prompt
    call print_string

    mov ecx, gender
    mov edx, 128
    call read_line
    jc gender_read_error

    call display_details

    cmp byte [gender + 1], 0
    jne show_invalid_gender

    mov al, [gender]

    cmp al, 'M'
    je show_male
    cmp al, 'm'
    je show_male

    cmp al, 'F'
    je show_female
    cmp al, 'f'
    je show_female

    jmp show_invalid_gender

gender_read_error:
    call display_details

show_invalid_gender:
    mov ecx, invalid_gender
    call print_string
    jmp exit_program

show_male:
    mov ecx, male_message
    call print_string
    jmp exit_program

show_female:
    mov ecx, female_message
    call print_string
    jmp exit_program

bad_age:
    mov ecx, age_error
    call print_string
    jmp exit_program

display_details:
    mov ecx, hello_name
    call print_string

    mov ecx, full_name
    call print_string

    mov ecx, newline
    call print_string

    mov ecx, age_prefix
    call print_string

    mov eax, [age]
    call print_uint

    mov ecx, age_suffix
    call print_string
    ret

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