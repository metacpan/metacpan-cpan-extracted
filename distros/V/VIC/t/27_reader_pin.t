use t::TestVIC tests => 1, debug => 0;
my $input_pin = <<'IN1';
PIC P16F690;

Main {
    digital_output RC0;
    digital_input RA0;
    read RA0, ISR {
        $value = shift;
        write RC0, $value;
    };
}

Simulator {
    attach_led RC0;
    log RA0, RC0;
    scope RA0, RC0;
    # a simple 100us high
    stimulate RA0, wave [
        100, 1, 2000, 0
    ];
    stop_after 10ms;
    autorun;
}
IN1

my $output_pin = <<'OUT1';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
VALUE res 1

cblock 0x70 ;; unbanked RAM that is common across all banks
ISR_STATUS
ISR_W
endc


;;;; generated code for macros
;;;;;;; ISR1_PARAM0 VARIABLES ;;;;;;
ISR1_PARAM0_UDATA udata
ISR1_PARAM0 res 1



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
	.sim "node rc0led"
	.sim "attach rc0led portc0 L0.in"

	.sim "log r porta"
	.sim "log w porta"
	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"porta0\""
	.sim "scope.ch1 = \"portc0\""

	.sim "echo creating stimulus number 0"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"

	.sim "{ 100,1,2000,0 }"
	.sim "name stim0"
	.sim "end"
	.sim "echo done creating stimulus number 0"
	.sim "node stim0RA0"
	.sim "attach stim0RA0 stim0 porta0"

	.sim "break c 100000"

	;;;; will autorun on start
	.sim "run"


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

_isr_ioca0:
	btfss INTCON, RABIF
	goto _end_isr_1
	bcf   INTCON, RABIF
	banksel PORTA
	btfsc PORTA, 0
	addlw 0x01
	banksel ISR1_PARAM0
	movwf ISR1_PARAM0
	goto _isr_1
_end_isr_1:

	goto _isr_exit

;;;; generated code for ISR1
_isr_1:

	;; moving ISR1_PARAM0 to VALUE
	movf ISR1_PARAM0, W
	movwf VALUE

;;;; assigning VALUE to a pin => using the last bit
	btfss VALUE, 0
	bcf PORTC, RC0
	btfsc VALUE, 0
	bsf PORTC, RC0

	goto _end_isr_1 ;; go back to end of block

;;;; end of _isr_1
_isr_exit:
	movf ISR_STATUS, W
	movwf STATUS
	swapf ISR_W, F
	swapf ISR_W, W
	retfie



;;;; generated code for Main
_start:

	banksel TRISC
	bcf TRISC, TRISC0
	banksel ANSEL
	bcf ANSEL, ANS4
	banksel PORTC
	bcf PORTC, 0

	banksel TRISA
	bsf TRISA, TRISA0
	banksel ANSEL
	bcf ANSEL, ANS0
	banksel PORTA

;; enable interrupt-on-change setup for RA0
	banksel INTCON
	bcf INTCON, RABIF
	bsf INTCON, GIE
	bsf INTCON, RABIE
	banksel IOCA
	bsf IOCA, IOCA0
;; end of interrupt-on-change setup

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
OUT1
compiles_ok($input_pin, $output_pin);
