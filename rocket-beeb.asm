;******************************************************************
; 6502 BBC Micro Compressed VGM (VGC) Music Player
; By Simon Morris
; https://github.com/simondotm/vgm-player-bbc
; https://github.com/simondotm/vgm-packer
;******************************************************************


; Allocate vars in ZP
ORG &70
GUARD &8f
.zp_start


;----------------------------------------------------------------------------------------------------------
; Common code headers
;----------------------------------------------------------------------------------------------------------
; Include common code headers here - these can declare ZP vars from the pool using SKIP...

INCLUDE "lib/vgcplayer_config.h.asm"
INCLUDE "lib/vgcplayer.h.asm"


.zp_end


rocket_vsync_count = &9C
rocket_audio_flag = &9E
rocket_fast_mode = &9F


\ ******************************************************************
\ *	Utility code - always memory resident
\ ******************************************************************

ORG &2000
GUARD &5800

.start

;----------------------------


;-------------------------------------------
; main
;-------------------------------------------

.entry
{
    JMP init        ; &0
    JMP play        ; &3
    JMP pause       ; &6
    JMP seek        ; &9
    JMP stop        ; &C
}

.init
{
    ; initialize the vgm player with a vgc data stream
    lda #hi(vgm_stream_buffers)
    ldx #lo(vgm_data)
    ldy #hi(vgm_data)
    sec ; set carry to enable looping
    jsr vgm_init

    lda #0:sta rocket_vsync_count:sta rocket_vsync_count+1

	sei
	lda &220:sta old_eventv ; EVENTV
	lda &221:sta old_eventv+1

    lda #LO(event_handler):sta &220     ; EVENTV
    lda #HI(event_handler):sta &221
    cli

    rts
}

.event_handler
{
	php
	cmp #4
	bne not_vsync

	\\ Preserve registers
	pha:txa:pha:tya:pha

	\\ Poll the music player
	jsr vgm_update

    \\ Update vsync count.
    {
        inc rocket_vsync_count
        bne no_carry
        inc rocket_vsync_count+1
        .no_carry
    }

	\\ Restore registers
	pla:tay:pla:tax:pla

	\\ Return
    .not_vsync
	plp
	rts
}

.play
{
	\\ Enable VSYNC event.
	lda #14
	ldx #4
	jmp &fff4
}

.pause
{
	\\ Disable VSYNC event.
	lda #13
	ldx #4
	jsr &fff4
    jmp sn_reset
}

.seek
{
    \ Assume paused!
    lda #&ff:sta rocket_fast_mode     ; turbo button on!
    jsr vgm_seek
    lda #0:sta rocket_fast_mode       ; turbo button off!
    rts
}

.stop
{
    jsr pause
	\\ Reset old Event handler
	sei
	lda old_eventv:sta &220
	lda old_eventv+1:sta &221
	cli 
	rts
}

.old_eventv equw 0

; code routines
INCLUDE "lib/vgcplayer.asm"

; include your tune of choice here, some samples provided....
.vgm_data
;INCBIN "music/vgc/song_091.vgc"
;INCBIN "music/vgc/axelf.vgc"
;INCBIN "music/vgc/bbcapple.vgc"
;INCBIN "music/vgc/nd-ui.vgc"
;INCBIN "music/vgc/outruneu.vgc"
;INCBIN "music/vgc/ym_009.vgc"
;INCBIN "music/vgc/test_bbc.vgc"
INCBIN "vgc/acid_demo.vgc"

ALIGN 256
.vgm_buffer_start

; reserve space for the vgm decode buffers (8x256 = 2Kb)
.vgm_stream_buffers
    skip 256
    skip 256
    skip 256
    skip 256
    skip 256
    skip 256
    skip 256
    skip 256

.vgm_buffer_end

.end

PRINT ~vgm_data

SAVE "Main", start, end, entry

PUTBASIC "rocket.bas", "rocket"
