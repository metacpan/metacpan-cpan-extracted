use Test::Lib;
use Test::VIC tests => 1, debug => 0;
my $input_port = <<'IN2';
PIC P16F690;

Main {
    digital_output PORTC;
    digital_input PORTB;
    read PORTB, ISR {
        $value = shift;
        write PORTC, $value;
    };
}

Simulator {
    attach_led PORTC, 8;
    log RB4, RB5, RB6, RB7;
    scope RB4, RB5, RB6, RB7;
    log RC4, RC5, RC6, RC7;
    scope RC4, RC5, RC6, RC7;
    stimulate RB4, wave [
        10001, 1, 20000, 0
    ];
    stimulate RB5, wave [
        20001, 1, 30000, 0
    ];
    stimulate RB6, wave [
        30001, 1, 40000, 0
    ];
    stimulate RB7, wave [
        40001, 1, 50000, 0
    ];
    stop_after 100ms;
    autorun;
}
IN2

my $output_port = <<'OUT2';
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
	.sim "module load led L4"
	.sim "L4.xpos = 400"
	.sim "L4.ypos = 250"
	.sim "L4.color = red"
	.sim "node portc4led"
	.sim "attach portc4led portc4 L4.in"
	.sim "module load led L5"
	.sim "L5.xpos = 400"
	.sim "L5.ypos = 300"
	.sim "L5.color = red"
	.sim "node portc5led"
	.sim "attach portc5led portc5 L5.in"
	.sim "module load led L6"
	.sim "L6.xpos = 400"
	.sim "L6.ypos = 350"
	.sim "L6.color = red"
	.sim "node portc6led"
	.sim "attach portc6led portc6 L6.in"
	.sim "module load led L7"
	.sim "L7.xpos = 400"
	.sim "L7.ypos = 400"
	.sim "L7.color = red"
	.sim "node portc7led"
	.sim "attach portc7led portc7 L7.in"

	.sim "log r portb"
	.sim "log w portb"
	.sim "log r portb"
	.sim "log w portb"
	.sim "log r portb"
	.sim "log w portb"
	.sim "log r portb"
	.sim "log w portb"

	.sim "scope.ch0 = \"portb4\""
	.sim "scope.ch1 = \"portb5\""
	.sim "scope.ch2 = \"portb6\""
	.sim "scope.ch3 = \"portb7\""

	.sim "log r portc"
	.sim "log w portc"
	.sim "log r portc"
	.sim "log w portc"
	.sim "log r portc"
	.sim "log w portc"
	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch4 = \"portc4\""
	.sim "scope.ch5 = \"portc5\""
	.sim "scope.ch6 = \"portc6\""
	.sim "scope.ch7 = \"portc7\""

	.sim "echo creating stimulus number 0"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"

	.sim "{ 10001,1,20000,0 }"
	.sim "name stim0"
	.sim "end"
	.sim "echo done creating stimulus number 0"
	.sim "node stim0RB4"
	.sim "attach stim0RB4 stim0 portb4"

	.sim "echo creating stimulus number 1"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"

	.sim "{ 20001,1,30000,0 }"
	.sim "name stim1"
	.sim "end"
	.sim "echo done creating stimulus number 1"
	.sim "node stim1RB5"
	.sim "attach stim1RB5 stim1 portb5"

	.sim "echo creating stimulus number 2"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"

	.sim "{ 30001,1,40000,0 }"
	.sim "name stim2"
	.sim "end"
	.sim "echo done creating stimulus number 2"
	.sim "node stim2RB6"
	.sim "attach stim2RB6 stim2 portb6"

	.sim "echo creating stimulus number 3"
	.sim "stimulus asynchronous_stimulus"
	.sim "initial_state 0"
	.sim "start_cycle 0"
	.sim "digital"

	.sim "{ 40001,1,50000,0 }"
	.sim "name stim3"
	.sim "end"
	.sim "echo done creating stimulus number 3"
	.sim "node stim3RB7"
	.sim "attach stim3RB7 stim3 portb7"

	.sim "break c 1000000"

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

_isr_iocb:
	btfss INTCON, RABIF
	goto _end_isr_1
	bcf   INTCON, RABIF
	banksel PORTB
	movf PORTB, W
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

	;; moving VALUE to PORTC
	movf VALUE, W
	movwf PORTC

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
	clrf TRISC
	banksel ANSEL
	movlw 0x0F
	andwf ANSEL, F
	banksel ANSELH
	movlw 0xFC
	andwf ANSELH, F

	banksel PORTC
	clrf PORTC

	banksel TRISB
	movlw 0xFF
	movwf TRISB
	banksel ANSEL
	movlw 0xFF
	andwf ANSEL, F
	banksel ANSELH
	movlw 0xF3
	andwf ANSELH, F

	banksel PORTB

;; enable interrupt-on-change setup for PORTB
	banksel INTCON
	bcf INTCON, RABIF
	bsf INTCON, GIE
	bsf INTCON, RABIE
	banksel IOCB
	clrf IOCB
	comf IOCB, F
;; end of interrupt-on-change setup

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
OUT2

compiles_ok($input_port, $output_port);
