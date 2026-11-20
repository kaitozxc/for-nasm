section .data
    name_prompt db "Enter student name: ", 0
    id_prompt db "Enter student ID: ", 0
    grade_prompt db "Enter grade: ", 0

    name_label db "Student Name: ", 0
    id_label db "Student ID: ", 0
    grade_label db "Grade: ", 0
    class_label db "Classification: ", 0

    excellent db "Excellent", 10, 0
    very_good db "Very Good", 10, 0
    good db "Good", 10, 0
    passed db "Passed", 10, 0
    failed db "Failed", 10, 0

    grade_error db "INVALID GRADE", 10, 0
    input_error db "INVALID INPUT", 10, 0
    newline db 10, 0

section .bss
    full_name resb 128
    student_id resb 128
    grade_text resb 128
    grade resd 1
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

    mov ecx, id_prompt
    call print_string

    mov ecx, student_id
    mov edx, 128
    call read_line
    jc bad_input

    mov ecx, grade_prompt
    call print_string

    mov ecx, grade_text
    mov edx, 128
    call read_line
    jc bad_grade

    mov esi, grade_text
    call parse_uint
    jc bad_grade

    cmp eax, 100
    ja bad_grade
    mov [grade], eax

    mov ecx, name_label
    call print_string

    mov ecx, full_name
    call print_string

    mov ecx, newline
    call print_string

    mov ecx, id_label
    call print_string

    mov ecx, student_id
    call print_string

    mov ecx, newline
    call print_string

    mov ecx, grade_label
    call print_string

    mov eax, [grade]
    call print_uint

    mov ecx, newline
    call print_string

    mov ecx, class_label
    call print_string

    mov eax, [grade]

    cmp eax, 90
    jae show_excellent

    cmp eax, 85
    jae show_very_good

    cmp eax, 80
    jae show_good

    cmp eax, 75
    jae show_passed

    jmp show_failed

show_excellent:
    mov ecx, excellent
    call print_string
    jmp exit_program

show_very_good:
    mov ecx, very_good
    call print_string
    jmp exit_program

show_good:
    mov ecx, good
    call print_string
    jmp exit_program

show_passed:
    mov ecx, passed
    call print_string
    jmp exit_program

show_failed:
    mov ecx, failed
    call print_string
    jmp exit_program

bad_grade:
    mov ecx, grade_error
    call print_string
    jmp exit_program

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