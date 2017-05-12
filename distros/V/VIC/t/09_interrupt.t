use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

pragma debounce count = 2;
pragma debounce delay = 1ms;
pragma adc right_justify = 0;

Main {
    digital_output PORTC;
    analog_input AN0;
    digital_input RA3;
    adc_enable 500kHz, AN0;
    $display = 0x08; # create a 8-bit register
    $dirxn = FALSE;
    timer_enable TMR0, 4kHz, ISR {#set the interrupt service routine
        adc_read $userval;
        $userval += 100;
    };
    Loop {
        write PORTC, $display;
        delay_ms $userval;
        debounce RA3, Action {
            $dirxn = !$dirxn;
        };
        if ($dirxn == TRUE) {
            rol $display, 1;
        } else {
            ror $display, 1;
        };
    }
}
...

my $output = << '...';
;;;; generated code for PIC header file
#include <p16f690.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
DIRXN res 1
DISPLAY res 1
USERVAL res 1

;;;;;; VIC_VAR_DEBOUNCE VARIABLES ;;;;;;;

VIC_VAR_DEBOUNCE_VAR_IDATA idata
;; initialize state to 1
VIC_VAR_DEBOUNCESTATE db 0x01
;; initialize counter to 0
VIC_VAR_DEBOUNCECOUNTER db 0x00



;;;;;; DELAY FUNCTIONS ;;;;;;;

VIC_VAR_DELAY_UDATA udata
VIC_VAR_DELAY   res 3



cblock 0x70 ;; unbanked RAM
ISR_STATUS
ISR_W
endc


;;;; generated code for macros
;; 1MHz => 1us per instruction
;; each loop iteration is 3us each
;; there are 2 loops, one for (768 + 3) us
;; and one for the rest in ms
;; we add 3 instructions for the outer loop
;; number of outermost loops = msecs * 1000 / 771 = msecs * 13 / 10
m_delay_ms macro msecs
    local _delay_msecs_loop_0, _delay_msecs_loop_1, _delay_msecs_loop_2
    variable msecs_1 = 0
    variable msecs_2 = 0
msecs_1 = (msecs * D'1000') / D'771'
msecs_2 = ((msecs * D'1000') % D'771') / 3 - 2;; for 3 us per instruction
    movlw   msecs_1
    movwf   VIC_VAR_DELAY + 1
_delay_msecs_loop_1:
    clrf   VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delay_msecs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delay_msecs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delay_msecs_loop_1
if msecs_2 > 0
    ;; handle the balance
    movlw msecs_2
    movwf VIC_VAR_DELAY
_delay_msecs_loop_2:
    decfsz VIC_VAR_DELAY, F
    goto _delay_msecs_loop_2
    nop
endif
    endm

;; 1MHz => 1us per instruction
;; each loop iteration is 3us each
;; there are 2 loops, one for (768 + 3) us
;; and one for the rest in ms
;; we add 3 instructions for the outermost loop
;; 771 * 256 + 3 = 197379 ~= 200000
;; number of outermost loops = seconds * 1000000 / 200000 = seconds * 5
m_delay_s macro secs
    local _delay_secs_loop_0, _delay_secs_loop_1, _delay_secs_loop_2
    local _delay_secs_loop_3
    variable secs_1 = 0
    variable secs_2 = 0
    variable secs_3 = 0
    variable secs_4 = 0
secs_1 = (secs * D'1000000') / D'197379'
secs_2 = ((secs * D'1000000') % D'197379') / 3
secs_4 = (secs_2 >> 8) & 0xFF - 1
secs_3 = 0xFE
    movlw   secs_1
    movwf   VIC_VAR_DELAY + 2
_delay_secs_loop_2:
    clrf    VIC_VAR_DELAY + 1   ;; set to 0 which gets decremented to 0xFF
_delay_secs_loop_1:
    clrf    VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delay_secs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delay_secs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delay_secs_loop_1
    decfsz  VIC_VAR_DELAY + 2, F
    goto    _delay_secs_loop_2
if secs_4 > 0
    movlw secs_4
    movwf VIC_VAR_DELAY + 1
_delay_secs_loop_3:
    clrf VIC_VAR_DELAY
    decfsz VIC_VAR_DELAY, F
    goto $ - 1
    decfsz VIC_VAR_DELAY + 1, F
    goto _delay_secs_loop_3
endif
if secs_3 > 0
    movlw secs_3
    movwf VIC_VAR_DELAY
    decfsz VIC_VAR_DELAY, F
    goto $ - 1
endif
    endm

;; 1MHz => 1us per instruction
;; return, goto and call are 2us each
;; hence each loop iteration is 3us
;; the rest including movxx + return = 2us
;; hence usecs - 6 is used
m_delay_us macro usecs
    local _delay_usecs_loop_0
    variable usecs_1 = 0
    variable usecs_2 = 0
if (usecs > D'6')
usecs_1 = usecs / D'3' - 2
usecs_2 = usecs % D'3'
    movlw   usecs_1
    movwf   VIC_VAR_DELAY
    decfsz  VIC_VAR_DELAY, F
    goto    $ - 1
    while usecs_2 > 0
        goto $ + 1
usecs_2--
    endw
else
usecs_1 = usecs
    while usecs_1 > 0
        nop
usecs_1--
    endw
endif
    endm

m_delay_wms macro
    local _delayw_msecs_loop_0, _delayw_msecs_loop_1
    movwf   VIC_VAR_DELAY + 1
_delayw_msecs_loop_1:
    clrf   VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delayw_msecs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delayw_msecs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delayw_msecs_loop_1
    endm




    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)


	org 0

	goto _start
	nop
	nop
	nop

	org 4
ISR:
_isr_entry:
	movwf ISR_W
	movf STATUS, W
	movwf ISR_STATUS

_isr_tmr0:
	btfss INTCON, T0IF
	goto _end_isr_1
	bcf   INTCON, T0IF
	goto _isr_1
_end_isr_1:

	goto _isr_exit

;;;; generated code for ISR
_isr_1:

	;;;delay 5us
	nop
	nop
	nop
	nop
	nop
	bsf ADCON0, GO
	btfss ADCON0, GO
	goto $ - 1
	movf ADRESH, W
	movwf USERVAL

	;;moves 100 to W
	movlw 0x64
	addwf USERVAL, F

	goto _end_isr_1;; go back to end of conditional

_isr_exit:
	movf ISR_STATUS, W
	movwf STATUS
	swapf ISR_W, F
	swapf ISR_W, W
	retfie



;;;; generated code for Main
_start:

	banksel TRISC
	clrf TRISC
    banksel ANSEL
    movlw 0x0F
    andwf ANSEL, F
    banksel ANSELH
    movlw 0xFC
    andwf ANSELH, F
	banksel PORTC
	clrf PORTC

	banksel TRISA
	bsf TRISA, TRISA0
	banksel ANSEL
    bsf ANSEL, ANS0
	banksel PORTA

	banksel TRISA
	bsf TRISA, TRISA3
	banksel PORTA

	banksel ADCON1
	movlw B'00000000'
	movwf ADCON1
	banksel ADCON0
	movlw B'00000001'
	movwf ADCON0

	;; moves 8 to DISPLAY
    banksel DISPLAY
	movlw 0x08
	movwf DISPLAY

	clrf DIRXN

;; timer prescaling
	banksel OPTION_REG
	clrw
	iorlw B'00000111'
	movwf OPTION_REG

;; enable interrupt servicing
	banksel INTCON
	bsf INTCON, GIE
	bcf INTCON, T0IF
	bsf INTCON, T0IE


;; clear the timer
	banksel TMR0
	clrf TMR0


;;;; generated code for Loop1
_loop_2:

	;; moves DISPLAY to PORTC
	movf  DISPLAY, W
	movwf PORTC

	movf USERVAL, W
	call _delay_wms

	;;; generate code for debounce A<3>
	call _delay_1ms

	;; has debounce state changed to down (bit 0 is 0)
	;; if yes go to debounce-state-down
	btfsc   VIC_VAR_DEBOUNCESTATE, 0
	goto    _debounce_state_up
_debounce_state_down:
	clrw
	btfss   PORTA, 3
	;; increment and move into counter
	incf    VIC_VAR_DEBOUNCECOUNTER, 0
	movwf   VIC_VAR_DEBOUNCECOUNTER
	goto    _debounce_state_check

_debounce_state_up:
	clrw
	btfsc   PORTA, 3
	incf    VIC_VAR_DEBOUNCECOUNTER, 0
	movwf   VIC_VAR_DEBOUNCECOUNTER
	goto    _debounce_state_check

_debounce_state_check:
	movf    VIC_VAR_DEBOUNCECOUNTER, W
	xorlw   0x02
	;; is counter == 2 ?
	btfss   STATUS, Z
	goto    _end_action_3
	;; after 2 straight, flip direction
	comf    VIC_VAR_DEBOUNCESTATE, 1
	clrf    VIC_VAR_DEBOUNCECOUNTER
	;; was it a key-down
	btfss   VIC_VAR_DEBOUNCESTATE, 0
	goto    _end_action_3
	goto    _action_3
_end_action_3:

_start_conditional_0:
    bcf STATUS, Z
	movf DIRXN, W
	xorlw 0x01
	btfss STATUS, Z ;; DIRXN == 1 ?
	goto _false_5
	goto _true_4
_end_conditional_0:


	goto _loop_2
_end_loop_2:
_end_start:
    goto $

;;;; generated code for functions
;;;; generated code for Action2
_action_3:

	;; clrw -- leftover from old code

;; generate code for !DIRXN
    movf DIRXN, W
    btfss STATUS, Z
    goto $ + 3
    movlw 1
    goto $ + 2
    clrw

	movwf DIRXN

	goto _end_action_3;; go back to end of conditional

_delay_1ms:
	m_delay_ms D'1'
	return

_delay_wms:
	m_delay_wms
	return

;;;; generated code for False2
_false_5:

	bcf STATUS, C
	rrf DISPLAY, 1
	btfsc STATUS, C
	bsf DISPLAY, 7

	goto _end_conditional_0;; go back to end of conditional

;;;; generated code for True2
_true_4:

	bcf STATUS, C
	rlf DISPLAY, 1
	btfsc STATUS, C
	bsf DISPLAY, 0

	goto _end_conditional_0;; go back to end of conditional



;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
