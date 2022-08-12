use Test::Lib;
use Test::Lib;
use Test::VIC tests => 1, debug => 0;

my $input = <<'...';
PIC PIC16F690;

# A Comment

Main { # set the Main function
     digital_output RC0; # mark pin RC0 as output
     write RC0, 1; # write the value 1 to RC0
} # end the Main function
...

my $output = <<'...';
#include <p16f690.inc>

    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)

org 0

_start:
    ;; turn on PORTC's pin 0 as output
     banksel   TRISC
     bcf       TRISC, TRISC0
     banksel   ANSEL
     bcf       ANSEL, ANS4
     banksel   PORTC
     bcf       PORTC, 0
     banksel   PORTC
     bsf       PORTC, 0
_end_start:
     goto      $
     end
...

compiles_ok($input, $output);
