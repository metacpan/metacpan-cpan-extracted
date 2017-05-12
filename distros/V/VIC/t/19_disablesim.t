use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

# A Comment
pragma simulator disable;

Main { # set the Main function
     digital_output RC0; # mark pin RC0 as output
     write RC0, 1; # write the value 1 to RC0
     sim_assert RC0 == 0x1, "Pin RC0 should be 1";
} # end the Main function

Simulator {
    attach_led RC0;
    stop_after 1s;
    logfile "helloworld.lxt";
    log RC0;
    scope RC0;
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>

;;;; generated code for variables

;;;; generated code for macros



    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)


	org 0

;;;; generated code for Main
_start:

	banksel TRISC
	bcf TRISC, TRISC0
	banksel ANSEL
	bcf ANSEL, ANS4
	banksel PORTC
	bcf PORTC, 0

    banksel PORTC
	bsf PORTC, 0

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
