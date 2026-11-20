BITS 32

%macro display 1
    pushad
    mov ecx, %1
    call print_text
    popad
%endmacro

section .data
    filename db 'coffee_receipt.txt', 0

    banner db 10
           db '              (  (  (', 10
           db '               )  )  )', 10
           db '             .--------.', 10
           db '             | COFFEE |]', 10
           db '             |________|', 10
           db '============ ISTARSBUCKS ============', 10, 0

    menu db 10, '1. Add order', 10
         db '2. View order', 10
         db '3. Finish order', 10
         db '4. Cancel order', 10
         db '5. Exit', 10
         db '6. Remove one item', 10
         db 'Choose an option: ', 0

    coffees db 10
            db '1. Americano           Php 160.00', 10
            db '2. Latte               Php 180.00', 10
            db '3. Mocha Latte         Php 175.00', 10
            db '4. Cappuccino          Php 180.00', 10
            db '5. Caramel Macchiato   Php 190.00', 10
            db '6. Spanish Latte       Php 195.00', 10
            db '7. Matcha              Php 205.00', 10
            db '0. Back to main menu', 10
            db 'Choose coffee [0-7]: ', 0

    again_prompt db 'Would you like to order again? [Y/N]: ', 0
    cash_prompt db 'Enter cash in whole peso: ', 0
    invalid_msg db 'Invalid input. Try again.', 10, 0
    added_msg db 'Order added.', 10, 0
    removed_msg db 'One item removed.', 10, 0
    missing_msg db 'That coffee is not in your order.', 10, 0
    limit_msg db 'You can order up to 99 of each coffee.', 10, 0
    remove_prompt db 'Choose the coffee number to remove one item.', 10, 0
    empty_msg db 'Your order is empty.', 10, 0
    cancelled_msg db 'Order cancelled.', 10, 0
    low_cash_msg db 'Not enough cash. Try again.', 10, 0
    saved_msg db 'Receipt saved to coffee_receipt.txt.', 10, 0

    error_msg db 'Receipt could not be saved. Your order is still here.', 10
              db 'Choose Finish order to try again.', 10, 0

    completed_msg db 'Order completed.', 10, 0
    goodbye_msg db 'Thank you! Come again!', 10, 0

    header db 10, '========== ISTARSBUCKS ==========', 10, 0
    times_text db ' x ', 0
    equals_text db ' = Php ', 0
    total_text db 'TOTAL: Php ', 0
    cash_text db 'CASH: Php ', 0
    change_text db 'CHANGE: Php ', 0
    cents_text db '.00', 0
    newline db 10, 0
    divider db '---------------------------------', 10, 0

    americano db 'Americano', 0
    latte db 'Latte', 0
    mocha db 'Mocha Latte', 0
    cappuccino db 'Cappuccino', 0
    caramel db 'Caramel Macchiato', 0
    spanish db 'Spanish Latte', 0
    matcha db 'Matcha', 0

    names dd americano, latte, mocha, cappuccino
          dd caramel, spanish, matcha

    prices dd 160, 180, 175, 180, 190, 195, 205

section .bss
    quantities resd 7
    total resd 1
    cash resd 1
    change resd 1
    receipt_fd resd 1
    saving resd 1
    save_failed resd 1
    input_char resb 1
    digits resb 16

section .text
    global _start

_start:
    cld
    display banner

main_menu:
    display menu
    call read_number

    cmp eax, 1
    je add_order

    cmp eax, 2
    je view_order

    cmp eax, 3
    je finish_order

    cmp eax, 4
    je cancel_order

    cmp eax, 5
    je exit_program

    cmp eax, 6
    je remove_order

    display invalid_msg
    jmp main_menu

add_order:
    display coffees
    call read_number

    cmp eax, 0
    je main_menu

    dec eax
    cmp eax, 6
    ja .invalid

    mov esi, eax
    cmp dword [quantities + esi * 4], 99
    jae .limit

    inc dword [quantities + esi * 4]
    mov eax, [prices + esi * 4]
    add [total], eax

    display added_msg
    jmp ask_more

.limit:
    display limit_msg
    jmp ask_more

.invalid:
    display invalid_msg
    jmp add_order

ask_more:
    display again_prompt
    call read_answer

    cmp eax, 'y'
    je add_order

    cmp eax, 'n'
    je main_menu

    display invalid_msg
    jmp ask_more

view_order:
    cmp dword [total], 0
    je empty_order

    call show_order
    jmp main_menu

remove_order:
    cmp dword [total], 0
    je empty_order

    call show_order
    display remove_prompt
    display coffees
    call read_number

    test eax, eax
    jz main_menu

    dec eax
    cmp eax, 6
    ja .invalid

    cmp dword [quantities + eax * 4], 0
    je .missing

    dec dword [quantities + eax * 4]
    mov eax, [prices + eax * 4]
    sub [total], eax

    display removed_msg
    jmp main_menu

.invalid:
    display invalid_msg
    jmp remove_order

.missing:
    display missing_msg
    jmp remove_order

cancel_order:
    cmp dword [total], 0
    je empty_order

    call clear_order
    display cancelled_msg
    jmp main_menu

clear_order:
    pushad

    xor eax, eax
    mov edi, quantities
    mov ecx, 7
    rep stosd

    mov [total], eax
    mov [cash], eax
    mov [change], eax

    popad
    ret

finish_order:
    cmp dword [total], 0
    je empty_order

    call show_order

.payment:
    display cash_prompt
    call read_number

    test eax, eax
    jz main_menu

    cmp eax, 999999
    ja .invalid_cash

    cmp eax, [total]
    jb .insufficient_cash

    mov [cash], eax
    sub eax, [total]
    mov [change], eax

    mov eax, 5
    mov ebx, filename
    mov ecx, 577
    mov edx, 0o644
    int 0x80

    test eax, eax
    js file_error

    mov [receipt_fd], eax
    mov dword [save_failed], 0
    mov dword [saving], 1

    call show_order

    display cash_text
    mov eax, [cash]
    call print_amount
    display newline

    display change_text
    mov eax, [change]
    call print_amount
    display newline

    display divider
    display goodbye_msg

    mov dword [saving], 0

    mov eax, 6
    mov ebx, [receipt_fd]
    int 0x80

    test eax, eax
    js file_error

    cmp dword [save_failed], 0
    jne file_error

    display saved_msg
    display completed_msg

    mov eax, 1
    xor ebx, ebx
    int 0x80

.invalid_cash:
    display invalid_msg
    jmp .payment

.insufficient_cash:
    display low_cash_msg
    jmp .payment

empty_order:
    display empty_msg
    jmp main_menu

show_order:
    display header
    xor esi, esi

.next:
    cmp dword [quantities + esi * 4], 0
    je .skip

    mov ecx, [names + esi * 4]
    call print_text
    display times_text

    mov eax, [quantities + esi * 4]
    call print_number
    display equals_text

    mov eax, [quantities + esi * 4]
    imul eax, [prices + esi * 4]
    call print_amount
    display newline

.skip:
    inc esi
    cmp esi, 7
    jb .next

    display divider
    display total_text

    mov eax, [total]
    call print_amount
    display newline
    ret

print_amount:
    call print_number
    display cents_text
    ret

print_number:
    pushad

    mov edi, digits + 15
    mov byte [edi], 0
    mov ebx, 10

.convert:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl

    test eax, eax
    jnz .convert

    mov ecx, edi
    call print_text

    popad
    ret

print_text:
    pushad
    xor edx, edx

.length:
    cmp byte [ecx + edx], 0
    je .write

    inc edx
    jmp .length

.write:
    mov ebx, 1
    call write_all

    cmp dword [saving], 1
    jne .done

    cmp dword [save_failed], 0
    jne .done

    mov ebx, [receipt_fd]
    call write_all

    test eax, eax
    jns .done

    mov dword [save_failed], 1

.done:
    popad
    ret

write_all:
    push ecx
    push edx

.next:
    test edx, edx
    jz .success

    mov eax, 4
    int 0x80

    cmp eax, -4
    je .next

    test eax, eax
    jle .failed

    add ecx, eax
    sub edx, eax
    jmp .next

.success:
    xor eax, eax
    jmp .done

.failed:
    mov eax, -1

.done:
    pop edx
    pop ecx
    ret

read_answer:
    xor esi, esi
    xor edi, edi

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80

    cmp eax, -4
    je .read

    test eax, eax
    jle .end_input

    movzx eax, byte [input_char]

    cmp al, 10
    je .done

    cmp al, 13
    je .read

    inc edi
    cmp edi, 1
    jne .read

    mov esi, eax
    jmp .read

.end_input:
    test edi, edi
    jz exit_program

.done:
    cmp edi, 1
    jne .bad

    mov eax, esi
    or eax, 32
    ret

.bad:
    mov eax, -2
    ret

read_number:
    xor esi, esi
    xor edi, edi
    xor ebp, ebp

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80

    cmp eax, -4
    je .read

    test eax, eax
    jle .end_input

    movzx eax, byte [input_char]

    cmp al, 10
    je .done

    cmp al, 13
    je .read

    inc edi
    sub eax, '0'

    cmp eax, 9
    ja .invalid

    test ebp, ebp
    jnz .read

    imul esi, 10
    add esi, eax

    cmp esi, 999999
    ja .invalid

    jmp .read

.invalid:
    mov ebp, 1
    jmp .read

.end_input:
    test edi, edi
    jz exit_program

.done:
    test edi, edi
    jz .bad

    test ebp, ebp
    jnz .bad

    mov eax, esi
    ret

.bad:
    mov eax, -2
    ret

file_error:
    mov dword [saving], 0
    display error_msg
    jmp main_menu

exit_program:
    display goodbye_msg

    mov eax, 1
    xor ebx, ebx
    int 0x80