use Test::Lib;
use Test::VIC tests => 1, debug => 0;
my $input = <<'...';
PIC P16F690;

Main {
    digital_input RC0;
    digital_output RC1;
    read RC1, $value;
    read RC0, Action {
        $value = shift;
        write RC1, $value;
    };
    sim_assert $value == 1;
}

Simulator {
    attach_led RC1;
    log RC1, RC0;
    scope RC1, RC0;
    # a simple 100us high
    stimulate RC0, wave [
        1, 1, 101, 0
    ];
    stop_after 100ms;
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
VALUE res 1
	global VALUE

;;;;;;; ACTION1_PARAM0 VARIABLES ;;;;;;
ACTION1_PARAM0_UDATA udata
ACTION1_PARAM0 res 1


;;;; generated code for macros


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
	.sim "node rc1led"
	.sim "attach rc1led portc1 L0.in"

	.sim "log r portc"
	.sim "log w portc"
	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"portc1\""
	.sim "scope.ch1 = \"portc0\""

	.sim "echo creating stimulus number 0"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"

	.sim "{ 1,1,101,0 }"
	.sim "name stim0"
	.sim "end"
	.sim "echo done creating stimulus number 0"
	.sim "node stim0RC0"
	.sim "attach stim0RC0 stim0 portc0"

	.sim "break c 1000000"

	;;;; will autorun on start
	.sim "run"




;;;; generated code for Main
_start:

	banksel TRISC
	bsf TRISC, TRISC0
	banksel ANSEL
	bcf ANSEL, ANS4
	banksel PORTC

	banksel TRISC
	bcf TRISC, TRISC1
	banksel ANSEL
	bcf ANSEL, ANS5
	banksel PORTC
	bcf PORTC, 1

;;; instant reading from RC1 into VALUE
	clrw
	banksel PORTC
	btfsc PORTC, 1
	addlw 0x01
	banksel VALUE
	movwf VALUE

;;; instant reading from RC0 into ACTION1_PARAM0
	clrw
	banksel PORTC
	btfsc PORTC, 0
	addlw 0x01
	banksel ACTION1_PARAM0
	movwf ACTION1_PARAM0
;;; invoking _action_1
	goto _action_1
_end_action_1:


	;; break if the condition evaluates to false
	.assert "VALUE == 0x01, \"VALUE == 0x01 is false\""
	nop ;; needed for the assert

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
;;;; generated code for Action1
_action_1:

	;; moving ACTION1_PARAM0 to VALUE
	movf ACTION1_PARAM0, W
	movwf VALUE

;;;; assigning VALUE to a pin => using the last bit
	btfss VALUE, 0
	bcf PORTC, RC1
	btfsc VALUE, 0
	bsf PORTC, RC1

	goto _end_action_1 ;; go back to end of block

;;;; end of _action_1

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);

