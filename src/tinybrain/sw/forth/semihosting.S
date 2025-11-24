.thumb

.macro do_semihosting
    bkpt #0xAB
.endm

.set SYS_EXIT, 0x18
.set SYS_WRITEC, 0x03
.set SYS_READC, 0x07

.set ADP_Stopped_ApplicationExit, 0x20026

.global sys_exit
.type sys_exit, %function
.thumb_func
sys_exit:
    mov r0, #SYS_EXIT
    ldr r1, =#ADP_Stopped_ApplicationExit
    do_semihosting
1:
    b 1b

.global sys_writec
.type sys_writec, %function
.thumb_func
sys_writec:
    push {r0}
    mov r1, sp
    mov r0, #SYS_WRITEC
    do_semihosting
    pop {r0}
    bx lr

.global sys_readc
.type sys_readc, %function
.thumb_func
sys_readc:
    mov r0, #SYS_READC
    mov r1, #0
    do_semihosting
    bx lr
