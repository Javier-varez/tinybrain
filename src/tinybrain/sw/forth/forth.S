.thumb
.syntax unified

// Register allocation
// - sp - data stack pointer
// - r4 - instruction pointer
// - r5 - return stack pointer
// - r6 - cur word addr

.macro next
    ldr r6, [r4], #4
    ldr pc, [r6]
.endm

.macro pushrsp reg
    str \reg, [r5, #-4]!
.endm

.macro poprsp reg
    ldr \reg, [r5], #4
.endm

    .text
    .align 4
    .thumb_func
    .global docol
docol:
    pushrsp r4
    add r4, r6, #4
    next

.set f_immed,0x80
.set f_hidden,0x20
.set f_lenmask,0x1f

.set link, 0

.macro defword name, namelen, label, flags=0
    .text
    .align 4
    .global word_forth_\label
word_forth_\label :
    .4byte link  // Setting the link to the previously-defined word. This is done at compile-time, as link is redefined
    .set link, word_forth_\label
    .byte \flags + \namelen
    .ascii "\name"
    .align 4
    .global forth_\label
forth_\label :
    .4byte docol
    // Actual code of the word
.endm

.macro defcode name, namelen, label, flags=0
    .text
    .align 4
    .global word_\label
word_forth_\label :
    .4byte link
    .set link, word_forth_\label
    .byte \flags + \namelen
    .ascii "\name"
    .align 4
    .global \label
forth_\label :
    .4byte code_forth_\label
    .thumb_func
    .global code_forth_\label
    .type code_forth_\label , %function
code_forth_\label :
    // Actual asm code of the word
.endm

.macro defconst name, namelen, label, value, flags=0
    defcode \name, \namelen, \label, \flags
    ldr r0, =#\value
    push { r0 }
    next
.endm

.macro call_ffi target
    mov r7, sp
    and r10, r7, #0xFFFFFFF0
    mov sp, r10
    and r7, r7, #0x0F
    bl \target
    add sp, r7
.endm

// Define all words here

defcode "EXIT", 4, exit
    poprsp r4
    next

defcode "LIT", 3, lit
    ldr r0, [r4], #4
    push { r0 }
    next

defcode "+", 1, add
    pop { r0, r1 }
    add r0, r1
    push { r0 }
    next

defcode "DUP", 3, dup
    pop { r0 }
    mov r1, r0
    push { r0, r1 }
    next

defcode "KEY", 3, key
    .global forth_key_impl
    .type forth_key_impl, %function
    call_ffi forth_key_impl
    push { r0 }
    next

defcode "WORD", 4, word
    .global forth_word_buffer
    .global forth_word_impl
    .type forth_word_impl, %function
    call_ffi forth_word_impl
    ldr r1, =forth_word_buffer
    push { r0, r1 }
    next

defconst "R0", 2, rz, end_rsp

defword "QUIT", 4, quit
    .4byte forth_rz
    .4byte forth_rspstore
    .4byte forth_interpret
    .4byte forth_branch
    .4byte -8

defword "INTERPRET", 9, interpret
    // FIXME: implement properly
    .4byte forth_word
    .4byte forth_exit

defcode "RSPSTORE", 9, rspstore
    pop { r5 }
    next

defcode "BRANCH", 6, branch
    ldr r0, [r4]
    add r4, r0
    next

// TODO: remove deadcode
// defword "EXAMPLE", 7, example
//     .4byte forth_lit
//     .4byte 3
//     .4byte forth_dup
//     .4byte forth_add
//     .4byte forth_exit

coldstart:
    .4byte forth_quit

enter_forth:
    ldr r4, =coldstart
    next

// The definition for LATEST has to go after all words are defined, to make sure that they are all captured
    .data
    .align 4
    .global latest
latest:
    .4byte link

    .data
    .align 4
begin_rsp:
    .skip 4096
end_rsp:

    .text
    .align 4
    .thumb_func
    .global main
    .type main, %function
main:
    .global sys_exit
    .type sys_exit, %function
    .global sys_writec
    .type sys_writec, %function

    mov r0, #'h'
    bl sys_writec
    mov r0, #'e'
    bl sys_writec
    mov r0, #'l'
    bl sys_writec
    mov r0, #'l'
    bl sys_writec
    mov r0, #'o'
    bl sys_writec
    mov r0, #'\n'
    bl sys_writec

    b enter_forth

    bl sys_exit
