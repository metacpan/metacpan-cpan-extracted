use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

pragma debounce count = 5;
pragma debounce delay = 1ms;

Main {
    digital_output PORTC;
    digital_input RA3;
    $display = 0;
    Loop {
        # test breaking of arguments over multiple lines
        debounce RA3,
        Action {
            ++$display;
            write PORTC, $display;
        };
    }
}

Simulator {
    attach_led PORTC, 4, 'red';
    logfile "debouncer.lxt";
    log RA3;
    scope RA3;
    # stimulus should reflect the debounce delay to be viable
    stimulate RA3, every 5s, wave [
        300, 1, 1300, 0,
        1400, 1, 2400, 0,
        2500, 1, 3500, 0,
        3600, 1, 4600, 0,
        4700, 1, 5700, 0,
        5800, 1, 6800, 0,
        6900, 1, 8000, 0
    ];
    stop_after 30s;
    autorun;
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
DISPLAY res 1

;;;;;; VIC_VAR_DEBOUNCE VARIABLES ;;;;;;;

VIC_VAR_DEBOUNCE_VAR_IDATA idata
;; initialize state to 1
VIC_VAR_DEBOUNCESTATE db 0x01
;; initialize counter to 0
VIC_VAR_DEBOUNCECOUNTER db 0x00



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

;;;; generated common code for the Simulator
	.sim "module library libgpsim_modules"
	.sim "p16f690.xpos = 200"
	.sim "p16f690.ypos = 200"
	.sim "p16f690.frequency = 4000000"

;;;; generated code for Simulator
	.sim "module load led L0"
	.sim "L0.xpos = 100"
	.sim "L0.ypos = 50"
	.sim "L0.color = red"
	.sim "node portc0led"
	.sim "attach portc0led portc0 L0.in"
	.sim "module load led L1"
	.sim "L1.xpos = 100"
	.sim "L1.ypos = 100"
	.sim "L1.color = red"
	.sim "node portc1led"
	.sim "attach portc1led portc1 L1.in"
	.sim "module load led L2"
	.sim "L2.xpos = 100"
	.sim "L2.ypos = 150"
	.sim "L2.color = red"
	.sim "node portc2led"
	.sim "attach portc2led portc2 L2.in"
	.sim "module load led L3"
	.sim "L3.xpos = 100"
	.sim "L3.ypos = 200"
	.sim "L3.color = red"
	.sim "node portc3led"
	.sim "attach portc3led portc3 L3.in"

	.sim "log lxt debouncer.lxt"

	.sim "log r porta"
	.sim "log w porta"

	.sim "scope.ch0 = \"porta3\""

	.sim "echo creating stimulus number 0"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"
	.sim "period 5000000"
	.sim "{ 300,1,1300,0,1400,1,2400,0,2500,1,3500,0,3600,1,4600,0,4700,1,5700,0,5800,1,6800,0,6900,1,8000,0 }"
	.sim "name stim0"
	.sim "end"
	.sim "echo done creating stimulus number 0"
	.sim "node stim0RA3"
	.sim "attach stim0RA3 stim0 porta3"

	.sim "break c 300000000"

	;;;; will autorun on start
	.sim "run"




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
	bsf TRISA, TRISA3

	banksel PORTA

;;; SET::ASSIGN::display::0

	;; moves 0 (0x00) to DISPLAY
	clrf DISPLAY

;;;; generated code for Loop1
_loop_1:

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
	xorlw   0x05
	;; is counter == 0x05 ?
	btfss   STATUS, Z
	goto    _end_action_2
	;; after 0x05 straight, flip direction
	comf    VIC_VAR_DEBOUNCESTATE, 1
	clrf    VIC_VAR_DEBOUNCECOUNTER
	;; was it a key-down
	btfss   VIC_VAR_DEBOUNCESTATE, 0
	goto    _end_action_2
	goto    _action_2
_end_action_2:


	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
;;;; generated code for Action2
_action_2:

	;; increments DISPLAY in place
	;; increment byte[0]
	incf DISPLAY, F

	;; moving DISPLAY to PORTC
	movf DISPLAY, W
	movwf PORTC

	goto _end_action_2 ;; go back to end of block

;;;; end of _action_2
_delay_1ms:
	m_delay_ms D'1'
	return


;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
