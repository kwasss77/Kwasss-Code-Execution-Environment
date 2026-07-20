; Kwasss Code Execution Environment 2026
default rel
global _start
extern GetModuleFileNameA, CreateFileA, SetFilePointer, ReadFile, CloseHandle, GetStdHandle, WriteConsoleA, ExitProcess

section .data
    token_exit db "exit", 0
    token_math db "m ", 0
    token_prnt db "print ", 0
    math_title db "[kc2e_m]: ", 0
    text_title db "[kc2e_t]: ", 0
    newline    db 10, 0

section .bss
    file_handle resq 1
    read_bytes  resq 1
    file_name   resb 512
    file_buffer resb 4096
    line_buffer resb 512
    num1        resq 1
    num2        resq 1
    result      resq 1
    res_utf8    resb 32
    stdout_h    resq 1
    chars_writ  resq 1
    arg_buffer  resb 512

section .text
_start:
    sub rsp, 64

    mov rcx, -11
    call GetStdHandle
    mov [stdout_h], rax

    xor rcx, rcx
    lea rdx, [file_name]
    mov r8, 512
    call GetModuleFileNameA

    mov rcx, file_name
    mov rdx, 0x80000000
    mov r8, 7
    mov r9, 0
    mov qword [rsp + 32], 3
    mov qword [rsp + 40], 128
    mov qword [rsp + 48], 0
    call CreateFileA
    mov [file_handle], rax

    cmp rax, -1
    je exit_program

    mov rcx, [file_handle]
    mov rdx, 3072
    xor r8, r8
    xor r9, r9
    call SetFilePointer

    mov rcx, [file_handle]
    mov rdx, file_buffer
    mov r8, 4096
    mov r9, read_bytes
    mov qword [rsp + 32], 0
    call ReadFile

    mov rcx, [file_handle]
    call CloseHandle

    mov rsi, file_buffer
    mov r12, file_buffer
    add r12, [read_bytes]

next_line:
    cmp rsi, r12
    jge exit_program

    lea rdi, [line_buffer]
    xor rcx, rcx

copy_line_loop:
    cmp rsi, r12
    jge line_copied
    mov al, [rsi]
    inc rsi
    cmp al, 13
    je skip_lf
    cmp al, 10
    je line_copied
    
    mov [rdi], al
    inc rdi
    inc rcx
    cmp rcx, 510
    jl copy_line_loop

skip_lf:
    cmp rsi, r12
    jge line_copied
    mov al, [rsi]
    cmp al, 10
    jne line_copied
    inc rsi

line_copied:
    mov byte [rdi], 0
    cmp rcx, 0
    je next_line

    lea rsi, [line_buffer]
    lea rdi, [token_exit]
    mov rcx, 4
    repe cmpsb
    je force_exit

    lea rsi, [line_buffer]
    lea rdi, [token_math]
    mov rcx, 2
    repe cmpsb
    je do_math

    lea rsi, [line_buffer]
    lea rdi, [token_prnt]
    mov rcx, 6
    repe cmpsb
    je do_print

    jmp line_done

force_exit:
    jmp exit_program

do_math:
    xor rax, rax
    mov al, [rsi]
    sub al, '0'
    mov [num1], rax
    inc rsi

    mov r10b, [rsi]
    inc rsi

    xor rax, rax
    mov al, [rsi]
    sub al, '0'
    mov [num2], rax

    mov rax, [num1]
    cmp r10b, '+'
    je op_add
    cmp r10b, '-'
    je op_sub
    cmp r10b, '*'
    je op_mul
    cmp r10b, '/'
    je op_div

    jmp line_done

op_add:
    add rax, [num2]
    jmp show_res
op_sub:
    sub rax, [num2]
    jmp show_res
op_mul:
    imul rax, [num2]
    jmp show_res
op_div:
    xor rdx, rdx
    idiv qword [num2]

show_res:
    mov [result], rax
    add al, '0'
    lea rdi, [res_utf8]
    mov [rdi], al
    mov byte [rdi+1], 0

    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 10
    lea rdx, [math_title]
    mov rcx, [stdout_h]
    call WriteConsoleA

    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 1
    lea rdx, [res_utf8]
    mov rcx, [stdout_h]
    call WriteConsoleA

    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 1
    lea rdx, [newline]
    mov rcx, [stdout_h]
    call WriteConsoleA
    jmp line_done

do_print:
    mov al, [rsi]
    cmp al, '['
    je do_print_var
    cmp al, '"'
    jne do_print_raw
    inc rsi

do_print_raw:
    lea rdi, [arg_buffer]
    xor al, al
    mov rcx, 512
    rep stosb

    lea rdi, [arg_buffer]
copy_raw_print:
    mov al, [rsi]
    cmp al, 0
    je render_raw_print
    cmp al, 13
    je term_raw_print
    cmp al, 10
    je term_raw_print
    cmp al, '"'
    je skip_print_quote
    mov [rdi], al
    inc rdi
skip_print_quote:
    inc rsi
    jmp copy_raw_print
term_raw_print:
    mov byte [rdi], 0
render_raw_print:
    lea rdi, [arg_buffer]
    xor r8, r8
count_len_raw_loop:
    cmp byte [rdi + r8], 0
    je print_raw_now
    inc r8
    jmp count_len_raw_loop
print_raw_now:
    mov r13, r8
    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 10
    lea rdx, [text_title]
    mov rcx, [stdout_h]
    call WriteConsoleA

    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, r13
    lea rdx, [arg_buffer]
    mov rcx, [stdout_h]
    call WriteConsoleA

    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 1
    lea rdx, [newline]
    mov rcx, [stdout_h]
    call WriteConsoleA
    jmp line_done

do_print_var:
    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 10
    lea rdx, [math_title]
    mov rcx, [stdout_h]
    call WriteConsoleA

    mov qword [rsp + 32], 0
    lea r9, [chars_writ]
    mov r8, 1
    lea rdx, [newline]
    mov rcx, [stdout_h]
    call WriteConsoleA
    jmp line_done

line_done:
    jmp next_line

exit_program:
    add rsp, 64
    mov rcx, 0
    call ExitProcess