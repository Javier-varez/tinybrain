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
    .align 2
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

.macro defheader name, namelen, label, flags=0
    .text
    .align 2
    .global word_forth_\label
word_forth_\label :
    .4byte link  // Setting the link to the previously-defined word. This is done at compile-time, as link is redefined
    .set link, word_forth_\label
    .byte \flags + \namelen
    .ascii "\name"
    .align 2
    .global forth_\label
forth_\label :
.endm

.macro defword name, namelen, label, flags=0
    defheader "\name", \namelen, \label, \flags
    .4byte docol // Interpreter for the word
    // Actual code of the word
.endm

.macro defcode name, namelen, label, flags=0
    defheader "\name", \namelen, \label, \flags
    .4byte code_forth_\label // No interpreter, jump to asm code

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

.macro defvar name, namelen, label, flags=0, initial=0
    defcode \name, \namelen, \label, \flags
    ldr r0, =forth_var_\label
    push { r0 }
    next

    .data
    .align 2
    .global forth_var_\label
forth_var_\label :
    .4byte \initial
.endm

.macro call_ffi target
    mov r7, sp
    and r10, r7, #0xFFFFFFF0
    mov sp, r10
    and r7, r7, #0x0F
    bl \target
    add sp, r7
.endm

// C++ helpers
.global forth_find_impl
.type forth_find_impl, %function

.global forth_key_impl
.type forth_key_impl, %function

.global forth_word_buffer

.global forth_word_impl
.type forth_word_impl, %function

.global forth_number_impl
.type forth_number_impl, %function

.global forth_dot_impl
.type forth_dot_impl, %function

// Define all words here

defcode "DROP", 4, drop
    pop { r0 }
    next

defcode "SWAP", 4, swap
    pop { r1, r2 }
    mov r0, r2
    push { r0, r1 }
    next

defcode "DUP", 3, dup
    ldr r0, [sp]
    push { r0 }
    next

defcode "OVER", 4, over
    ldr r0, [sp, #4]
    push { r0 }
    next

defcode "ROT", 3, rot
    pop { r1, r2, r3 }
    mov r0, r3
    push { r0, r1, r2 }
    next

defcode "-ROT", 4, neg_rot
    pop { r0, r1, r2 }
    mov r3, r0
    push { r1, r2, r3 }
    next

defcode "2DROP", 5, two_drop
    pop { r0 }
    pop { r0 }
    next

defcode "2DUP", 4, two_dup
    ldr r0, [sp]
    ldr r1, [sp, #4]
    push { r0, r1 }
    next

defcode "2SWAP", 5, two_swap
    pop { r0, r1, r2, r3 }
    push { r0, r1 }
    push { r2, r3 }
    next

defcode "?DUP", 4, qdup
    ldr r0, [sp]
    cmp r0, #0
    it ne
    pushne { r0 }
    next

defcode "1+", 2, incr
    ldr r0, [sp]
    add r0, #1
    str r0, [sp]
    next

defcode "1-", 2, decr
    ldr r0, [sp]
    sub r0, #1
    str r0, [sp]
    next

defcode "4+", 2, incr4
    ldr r0, [sp]
    add r0, #4
    str r0, [sp]
    next

defcode "4-", 2, decr4
    ldr r0, [sp]
    sub r0, #4
    str r0, [sp]
    next

defcode "+", 1, add
    pop { r0, r1 }
    add r0, r1
    push { r0 }
    next

defcode "-", 1, sub
    pop { r0, r1 }
    sub r0, r1
    push { r0 }
    next

defcode "*", 1, mult
    pop { r0, r1 }
    mul r0, r1
    push { r0 }
    next

defcode "/MOD", 4, divmod
    pop { r1, r2 }
    sdiv r0, r1, r2
    mls r1, r0, r2, r1
    push { r0, r1 }
    next

defcode "=", 1, equ
    pop { r0, r1 }
    sub r1, r0, r1
    negs r0, r1
    adc r0, r0, r1
    push { r0 }
    next

defcode "<>", 2, nequ
    pop { r0, r1 }
    subs r0, r1
    it ne
    movne r0, #1
    push { r0 }
    next

defcode "<", 1, less_than
    pop { r0, r1 }
    subs r0, r1
    ite gt
    movgt r0, #1
    movle r0, #0
    push { r0 }
    next

defcode ">", 1, greater_than
    pop { r0, r1 }
    subs r0, r1
    ite lt
    movlt r0, #1
    movge r0, #0
    push { r0 }
    next

defcode "<=", 2, less_eq
    pop { r0, r1 }
    subs r0, r1
    ite ge
    movge r0, #1
    movlt r0, #0
    push { r0 }
    next

defcode ">=", 2, greater_eq
    pop { r0, r1 }
    subs r0, r1
    ite le
    movle r0, #1
    movgt r0, #0
    push { r0 }
    next

defcode "0=", 2, zequ
    pop { r0 }
    // (clz(r0) >> 5), is only 1 for r0 == 0
    clz r0, r0
    lsr r0, r0, #5
    push { r0 }
    next

defcode "0<>", 3, znequ
    pop { r0 }
    cmp r0, #0
    it ne
    movne r0, #1
    push { r0 }
    next

defcode "0<", 2, zless_than
    pop { r0 }
    cmp r0, #0
    ite lt
    movlt r0, #1
    movge r0, #0
    push { r0 }
    next

defcode "0>", 2, zgreater_than
    pop { r0 }
    cmp r0, #0
    ite gt
    movgt r0, #1
    movle r0, #0
    push { r0 }
    next

defcode "0<=", 3, zless_eq
    pop { r0 }
    cmp r0, #0
    ite le
    movle r0, #1
    movgt r0, #0
    push { r0 }
    next

defcode "0>=", 3, zgreater_eq
    pop { r0 }
    cmp r0, #0
    ite ge
    movge r0, #1
    movlt r0, #0
    push { r0 }
    next

defcode "AND", 3, and
    pop { r0, r1 }
    and r0, r1
    push { r0 }
    next

defcode "OR", 2, or
    pop { r0, r1 }
    orr r0, r1
    push { r0 }
    next

defcode "XOR", 3, xor
    pop { r0, r1 }
    eor r0, r1
    push { r0 }
    next

defcode "INVERT", 6, invert
    pop { r0 }
    mvn r0, r0
    push { r0 }
    next

defcode "EXIT", 4, exit
    poprsp r4
    next

defcode "LIT", 3, lit
    ldr r0, [r4], #4
    push { r0 }
    next

defcode "KEY", 3, key
    call_ffi forth_key_impl
    push { r0 }
    next

defcode "WORD", 4, word
    call_ffi forth_word_impl
    ldr r1, =forth_word_buffer
    push { r0, r1 }
    next

defcode ".", 1, print
    pop { r0 }
    call_ffi forth_dot_impl
    next

// QUIT is a special word that resets the return stack pointer and re-enters the interpreter.
// It can be called from anywhere .
defword "QUIT", 4, quit
    .4byte forth_rz
    .4byte forth_rspstore
    .4byte forth_interpret
    .4byte forth_branch
    .4byte -8

defcode "INTERPRET", 9, interpret
    // FIXME: Add compilation support

    // Read a word from the input
    call_ffi forth_word_impl
    ldr r1, =forth_word_buffer
    mov r11, r0 // Save for later, in case we don't find the word right away

    // Try to find the word in the dictionary
    call_ffi forth_find_impl

    cmp r0, #0
    beq 1f // not found
    bpl 2f // immediate

    // found, not immediate
    ldr r0, =forth_var_state
    ldr r0, [r0]
    cmp r0, #0

    bne 3f // compilation mode

    // Interpret word

    add r0, r1, #4 // skip ptr
    ldrb r1, [r0]
    and r1, f_lenmask
    // align up to 4-byte boundary and skip len + flags byte
    add r1, #4
    and r1, #~3
    add r6, r0, r1

    // execute word
    ldr pc, [r6]

1:
    // Not found. Check if it is a number, then add it
    mov r0, r11 // word len
    ldr r1, =forth_word_buffer
    call_ffi forth_number_impl

    cmp r1, #1
    bne 4f // Unknown word, handle error
    push { r0 }
    next

2:
    // Immediate
    // FIXME: Not implemented
    bkpt #0x0000

3:
    // Compile
    // FIXME: Not implemented
    bkpt #0x0000

    next

4:
    // Number parsing failed
    // FIXME: Not implemented
    bkpt #0x0000

defcode "RSPSTORE", 9, rspstore
    pop { r5 }
    next

defcode "BRANCH", 6, branch
    ldr r0, [r4]
    add r4, r0
    next

defcode "FIND", 4, find
    pop { r0, r1 }
    call_ffi forth_find_impl
    push { r0, r1 }
    next

coldstart:
    .4byte forth_quit

enter_forth:
    ldr r4, =coldstart
    next

// The definition for LATEST has to go after all words are defined, to make sure that they are all captured
defvar "LATEST", 6, latest, 0, link
defvar "STATE", 5, state // 0 -> Immediate mode. 1 -> Compilation mode
defvar "HERE", 4, here
defvar "S0", 2, sz

.set tinybrain_forth_version, 48

defconst "VERSION", 7, version, tinybrain_forth_version
defconst "R0", 2, rz, end_rsp
defconst "F_IMMED", 7, __f_immed, f_immed
defconst "F_HIDDEN", 8, __f_hidden, f_hidden
defconst "F_LENMASK", 9, __f_lenmask, f_lenmask

    .data
    .align 2
begin_rsp:
    .skip 4096
end_rsp:

    .text
    .align 2
    .thumb_func
    .global main
    .type main, %function
main:
    b enter_forth
    bl sys_exit
