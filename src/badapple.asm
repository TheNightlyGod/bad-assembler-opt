; -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- ;
;        BAD ASSEMBLER (Optimized)      ;
;   bad apple written in NASM for x86   ;
;                real mode              ;
; -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- ;

use16
org 0x7C00

; ----------------- CONFIG -----------------
%define VIDEO_W        160
%define VIDEO_H        100
%define MODE13_FREQUENCY 0xE90B
%define INT0_OFFSET    8
%define DRIVE          0
%define CYL_START      0
%define SEC_START      2
%define SECTORS        36
%define BUF_SEG        0x1000
%define BPS            (SECTORS*512)

_start:
    cli
    mov al,0x43
    out 0x43,al
    mov ax,MODE13_FREQUENCY
    out 0x40,al
    mov al,ah
    out 0x40,al
    xor ax,ax
    mov word [INT0_OFFSET*4], isr_timer
    mov word [INT0_OFFSET*4+2], ax
    sti
    xor ah,ah
    mov al,0x13
    int 0x10
    call play
    jmp $

;----------------- PLAYBACK ----------------
play:
    mov ch,CYL_START
    mov cl,SEC_START
.loop:
    ; read sectors
    mov ah,2
    mov al,SECTORS
    xor dh,dh
    mov dl,DRIVE
    mov bx,BUF_SEG
    mov es,bx
    xor bx,bx
    int 0x13
    xor si,si
.decode:
    mov ds,BUF_SEG
    lodsb
    test al,al
    jz .done
    mov ah,al
    shr al,7
    and ah,0x7F
    ; set draw color
    or al,0x0F
.draw:
    test ah,ah
    jz .next
    dec ah
    call draw_pixel_2x2
    call sync_inc
    jmp .draw
.next:
    cmp si,BPS
    jne .decode
    inc ch
    jmp .loop
.done:
    ret

;----------------- DRAW & SYNC --------------
sync_inc:
    mov ax,[frame_pos]
    inc ax
    cmp ax, (VIDEO_W*VIDEO_H)
    jb .store
    mov byte [frame_sync],1
    xor ax,ax
.store:
    mov [frame_pos],ax
    ret

draw_pixel_2x2:
    mov bx,[frame_pos]
    mov ax,bx
    xor dx,dx
    mov bx,VIDEO_W
    div bx
    mov di,ax
    mov si,dx
    shl si,1
    shl di,1
    mov dl,[color]
    mov ax,0xA000
    mov es,ax
    mov bx,di
    imul bx,320
    add bx,si
    mov [es:bx],dl
    inc si
    mov [es:bx+1],dl
    add bx,320
    mov [es:bx],dl
    mov [es:bx-1],dl
    ret

;---------------- INTERRUPT ------------------
isr_timer:
    mov byte [frame_sync],0
    mov al,0x20
    out 0x20,al
    iret

;--------------- DATA & BSS -----------------
frame_sync: db 0
frame_pos:  dw 0
color:      db 0

times 510-($-$$) db 0
dw 0xAA55
