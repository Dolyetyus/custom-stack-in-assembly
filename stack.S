#define MAX_SIZE 8

.data
    top:    .quad -1
    sum:    .quad 0
    size:   .quad MAX_SIZE

.text
    formatstr:  .asciz "%ld"
    format_out: .asciz "%ld\n"
    how_to:     .asciz "How to use the stack:"
    options:    .asciz "\n1-Push\n2-Pop\n3-Peek\n4-Total\n5-Is Empty?\n6-Display\n0-Exit\n"
    opcode:     .asciz "\nEnter the operation code: "

    empty:      .asciz "The stack is empty\n"
    not_empty:  .asciz "The stack is NOT empty\n"
    push_str:   .asciz "Enter the element to add onto the stack: "
    pop_str:    .asciz "Popped element: %ld\n"
    top_str:    .asciz "Top element on the stack: %ld\n"
    total_str:  .asciz "The total value of the elements in the stack: %ld\n"
    dsply_str:  .asciz "The stack: \n"
    invalid_str:.asciz "Invalid operation choice\n"
    exit_str:   .asciz "Exiting the program...\n"

.global main
main:
    pushq   %rbp
    movq    %rsp, %rbp

    subq    $16, %rsp

    movq    size(%rip), %rdi
    imulq   $8, %rdi
    call    malloc
    movq    %rax, %r12                  # stack[size] = %r12
    
    leaq    how_to(%rip), %rdi
    call    printf

    leaq    options(%rip), %rdi
    call    printf

main_loop:
    leaq    opcode(%rip), %rdi
    call    printf
    
    leaq    -8(%rbp), %rsi              # load address of the variable to store user operation choice
    leaq    formatstr(%rip), %rdi
    call    scanf

    cmpq    $1, -8(%rbp)
    je      push
    cmpq    $2, -8(%rbp)
    je      pop
    cmpq    $3, -8(%rbp)
    je      peek
    cmpq    $4, -8(%rbp)
    je      total
    cmpq    $5, -8(%rbp)
    je      is_empty
    cmpq    $6, -8(%rbp)
    je      display
    cmpq    $0, -8(%rbp)
    je      exit
    jmp     invalid

invalid:
    leaq    invalid_str(%rip), %rdi
    call    printf
    jmp     main_loop

exit:
    leaq    exit_str(%rip), %rdi
    call    printf

    movq    %r12, %rdi
    call    free

    movq    %rbp, %rsp
    popq    %rbp
    
    movq    $0, %rax
    ret

# Variables: %r12 = stack, %r13 temp
push:
    movq    size(%rip), %rdx
    decq    %rdx

    cmpq    %rdx, top(%rip)
    je      expand_size                 # top == size-1

    leaq    push_str(%rip), %rdi
    call    printf                      

    leaq    -16(%rbp), %rsi
    leaq    formatstr(%rip), %rdi
    call    scanf

    addq    $1, top(%rip)
    movq    -16(%rbp), %rax   
    movq    top(%rip), %rdx           
    movq    %rax, (%r12, %rdx, 8)       # stack[top] = x
    addq    %rax, sum(%rip)             # sum += x

    jmp     end_push

expand_size:
    addq    $MAX_SIZE, size(%rip)

    movq    %r12, %rdi
    movq    size(%rip), %rsi
    imulq   $8, %rsi
    call    realloc                     # realloc(stack, size * sizeof(long))

    movq    %rax, %r12
    jmp     push

end_push:
    jmp     main_loop

pop:
    cmpq    $-1, top(%rip)
    je      stack_empty                 # top == -1

    movq    top(%rip), %rdx
    movq    (%r12, %rdx, 8), %r13       # temp = stack[top]

    leaq    pop_str(%rip), %rdi
    movq    %r13, %rsi
    call    printf
    
    subq    $1, top(%rip)               # top--
    subq    %r13, sum(%rip)             # sum -= temp

    cmpq    $-1, top(%rip)
    je      end_pop

    movq    top(%rip), %rdx
    movq    size(%rip), %rax
    subq    $MAX_SIZE, %rax

    cmpq    %rax, %rdx
    jl      shrink_size

    jmp     end_pop

shrink_size:
    subq    $MAX_SIZE, size(%rip)

    movq    %r12, %rdi
    movq    size(%rip), %rsi
    imulq   $8, %rsi
    call    realloc                     # realloc(stack, size * sizeof(long))

    jmp     end_pop

stack_empty:
    leaq    empty(%rip), %rdi
    call    printf

end_pop:
    jmp     main_loop

peek:
    cmpq    $-1, top(%rip)
    je      stack_empty                 # top == -1

    movq    top(%rip), %rdx
    movq    (%r12, %rdx, 8), %r13       # temp = stack[top]

    leaq    top_str(%rip), %rdi
    movq    %r13, %rsi
    call    printf

    jmp     main_loop

total:
    cmpq    $-1, top(%rip)
    je      stack_empty                 # top == -1

    leaq    total_str(%rip), %rdi
    movq    sum(%rip), %rsi
    call    printf

    jmp     main_loop

is_empty:
    cmpq    $-1, top(%rip)
    je      stack_empty                 # top == -1

    leaq    not_empty(%rip), %rdi
    call    printf

    jmp     main_loop

display:
    cmpq    $-1, top(%rip)
    je      stack_empty                 # top == -1

    leaq    dsply_str(%rip), %rdi
    call    printf

    movq    top(%rip), %rcx

display_loop:
    cmpq    $0, %rcx
    jl      main_loop

    pushq   %rcx                        # save loop counter or it gets lost since printf changes the value of %rcx
    pushq   %rcx                        # 16 byte alignment

    leaq    format_out(%rip), %rdi
    movq    (%r12, %rcx, 8), %rsi
    call    printf

    popq    %rcx                        # restore loop counter
    popq    %rcx

    decq    %rcx
    jmp     display_loop
