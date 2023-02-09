
org 100h

start:
    mov     al, 0x13
    int     0x10
    mov     dx, 0x3C8       ; set palette
    out     dx, al
    inc     dx
.paletteloop:
    out     dx, al          ; simple grayscale palette
    out     dx, al
    out     dx, al
    inc     ax
    jnz     .paletteloop
    push    0xA000 - 10     ; shift the segment by half a line to center X on screen
    pop     es
    mov     dx, interrupt   ; set interrupt handler
    mov     ax, 0x251C
    int     0x21
    mov     dx, 0x331       ; MIDI Control Port
    mov     al, 0x3F        ; enable MIDI
    out     dx, al
    dec     dx              ; shift dx to MIDI data port
    rep outsb               ; CX is still 0xFF so dumps the whole code to MIDI data port
main:
    xor     si, si
    mov     cl, 63
.loop:
    mov     ax, 0xCCCD
    .mutant equ $-2
    mul     di
    mov     al, dh
    sbb     al, 100
    imul    cl
    xchg    ax, dx
    imul    cl
    add     ax, 128
    add     dx, bx
    mov     al, cl
    add     al, 201
    .time equ $-1
    mul     ah
    and     al, dh
    jnz      .skip
    inc     si
.skip:
    loop    .loop
    xchg    ax, si
    stosb                   ; put pixel on screen
    imul    di, 85          ; "random" dithering
    jmp     main

interrupt:
    mov     dx, 0x330       ; MIDI data port again, we almost could've done all midi init here, but
    mov     si, song-1      ; the low bass pad would retriggered every interrupt, so didn't.
    add     byte [si],17    ; 17*15 = 255 = -1, so in 15 interrupts the song goes one step backward
    inc     byte [main.time+si-song+1] ; mutate the camera z in the main loop
    lodsb                   ; load time
    outsb                   ; output 0x9F = Note on
    mov     bx, si          ; bx is now pointing to the song
    xlat                    ; Load note, 0 means no note
    dec     ax              ; note--, 0 => 255 = invalid note, so it will not play actually anything
    out     dx, al
    add     al, 0xCD        ; mess with the rrrrola constant
    mov     [main.mutant], al ; Sync the raycaster step size to current note
    outsb                   ; The first note of the melody is also the note volume

data:
    db      0xCF    ; MIDI command: Set instrument on channel 0xF, 0xCF is also iret for the interrupt
    db      26      ; Instrument id 26
    db      0xC0    ; MIDI command: Set instrument on channel 0
    db      95      ; Instrument id 95
    db      0x90    ; MIDI command: Note On, channel 0
    db      28      ; One octave down from the tonic of the melody (melody starts on note 40)
    db      119-17*3  ; Pretty loud, but not max vol, this is reused as the song time
                    ; and chosen to have the melody start at correct position
song:
    db      0x9F    ; MIDI command: Note On, channel 0xF
    db      41, 39, 43, 0, 48, 51, 53, 0, 48, 51, 46, 0, 48, 51, 53
