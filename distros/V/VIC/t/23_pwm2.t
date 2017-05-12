use Test::More;
use t::TestVIC tests => 1, debug => 0;

my $input = << '...';
PIC P16F690;

Main {
    # arg1 - pwm frequency
    # arg2 - duty cycle ratio in percentage
    pwm_single 1220Hz, 20%, CCP1;
    delay 5s;
    pwm_update 1220Hz, 30%; # update duty cycle
    delay 5s;
}
...

my $output = << '...';
;;;; generated code for PIC header file
#include <p16f690.inc>

;;;; generated code for variables

;;;;;; DELAY FUNCTIONS ;;;;;;;

VIC_VAR_DELAY_UDATA udata
VIC_VAR_DELAY   res 3



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




    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)


	org 0





;;;; generated code for Main
_start:

;;; PWM Type: single
;;; PWM Frequency = 1220 Hz
;;; Duty Cycle = 20 / 100
;;; CCPR1L:CCP1CON<5:4> = 164
;;; CCPR1L = 0x29
;;; CCP1CON = b'00001100'
;;; T2CON = b'00000101'
;;; PR2 = 0xCB
;;; PSTRCON = b'00010001'
;;; PWM1CON = 0x80
;;; Prescaler = 4
;;; Fosc = 4000000
;;; disable the PWM output driver for CCP1 by setting the associated TRIS bit
	banksel TRISC
	bsf TRISC, TRISC5

;;; set PWM period by loading PR2
	banksel PR2
	movlw 0xCB
	movwf PR2
;;; configure the CCP module for the PWM mode by setting CCP1CON
	banksel CCP1CON
	movlw b'00001100'
	movwf CCP1CON
;;; set PWM duty cycle
	movlw 0x29
	movwf CCPR1L
;;; configure and start TMR2
;;; - clear TMR2IF flag of PIR1 register
	banksel PIR1
	bcf PIR1, TMR2IF
	movlw b'00000101'
	movwf T2CON
;;; enable PWM output after a new cycle has started
	btfss PIR1, TMR2IF
	goto $ - 1
	bcf PIR1, TMR2IF
;;; enable CCP1 pin output driver by clearing the associated TRIS bit
	banksel PSTRCON
	movlw b'00010001'
	movwf PSTRCON

;;; disable auto-shutdown mode
	banksel ECCPAS
	clrf ECCPAS
;;; set PWM1CON if half bridge mode
	banksel PWM1CON
	movlw 0x80
	movwf PWM1CON
	banksel TRISC
	bcf TRISC, TRISC5


	call _delay_5s

;;; updating PWM duty cycle for a given frequency
;;; PWM Frequency = 1220 Hz
;;; Duty Cycle = 30 / 100
;;; CCPR1L:CCP1CON<5:4> = 245
;;; CCPR1L = 0x3D
;;; update CCPR1L and CCP1CON<5:4> or the DC1B[01] bits
	bsf CCP1CON, DC1B0
	bcf CCP1CON, DC1B1
	movlw 0x3D
	movwf CCPR1L

	call _delay_5s

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
_delay_5s:
	m_delay_s D'5'
	return


;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);

