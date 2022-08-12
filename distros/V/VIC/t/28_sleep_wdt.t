use Test::Lib;
use Test::VIC tests => 1, debug => 0;

my $input = <<'...';

PIC P16F690;

Main {
    digital_output RC0;
    timer_enable WDT, 17ms;
    sleep;
    write RC0, 1;
}

Simulator {
    attach_led RC0;
    log RC0;
    scope RC0;
    stop_after 500ms;
    autorun;
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables

;;;; generated code for macros


	__config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_ON & _WDT_ON)


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

	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"portc0\""

	.sim "break c 5000000"

	;;;; will autorun on start
	.sim "run"




;;;; generated code for Main
_start:

	banksel TRISC
	bcf TRISC, TRISC0
	banksel ANSEL
	bcf ANSEL, ANS4
	banksel PORTC
	bcf PORTC, 0

;;; Period is 17000 us so scale is 1:512
	clrwdt
	clrw
	banksel WDTCON
	iorlw B'00001001'
	movwf WDTCON

	clrwdt ;; ensure WDT is cleared
	sleep
	nop ;; in case the user is using interrupts to wake up

	banksel PORTC
	bsf PORTC, 0

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
