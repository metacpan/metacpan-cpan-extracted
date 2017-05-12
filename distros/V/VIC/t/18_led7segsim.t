use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC p16f690;

pragma variable export;
# enable gpsim as a simulator
pragma simulator gpsim;

Main {
    $led7 = table [ 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D,
              0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, # this is gpsim specific
              0x58, 0x5E, 0x79, 0x71 ];
    $digit = 0;
    digital_output PORTA;
    digital_output PORTC;
    write PORTA, 0;
    Loop {
        write PORTC, $led7[$digit];
        $digit++;
        $digit &= 0x0F; # bounds check
    }
}

Simulator {
    attach_led7seg RA0, PORTC;
    stop_after 5s;
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
DIGIT res 1
VIC_EL_01 res 1
	global DIGIT, VIC_EL_01

GLOBAL_VAR_IDATA idata
VIC_TBLSZ_LED7 equ 0x10 ; size of table at _table_led7

;;;; generated code for macros



    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)


	org 0

;;;; generated common code for the Simulator
	.sim "module library libgpsim_modules"
	.sim "p16f690.xpos = 200"
	.sim "p16f690.ypos = 200"
	.sim "p16f690.frequency = 4000000"

;;;; generated code for Simulator
	.sim "module load led_7segments L0"
	.sim "L0.xpos = 500"
	.sim "L0.ypos = 50"
	.sim "node cc"
	.sim "attach cc porta0 L0.cc"
	.sim "node seg0"
	.sim "attach seg0 portc0 L0.seg0"
	.sim "node seg1"
	.sim "attach seg1 portc1 L0.seg1"
	.sim "node seg2"
	.sim "attach seg2 portc2 L0.seg2"
	.sim "node seg3"
	.sim "attach seg3 portc3 L0.seg3"
	.sim "node seg4"
	.sim "attach seg4 portc4 L0.seg4"
	.sim "node seg5"
	.sim "attach seg5 portc5 L0.seg5"
	.sim "node seg6"
	.sim "attach seg6 portc6 L0.seg6"

	.sim "break c 50000000"




;;;; generated code for Main
_start:

;;; SET::ASSIGN::digit::0

	;; moves 0 (0x00) to DIGIT
	clrf DIGIT

	banksel TRISA
	clrf TRISA
	banksel ANSEL
	movlw 0xF0
	andwf ANSEL, F
	banksel ANSELH
	movlw 0xFF
	andwf ANSELH, F

	banksel PORTA
	clrf PORTA

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

	;; moves 0 (0x00) to PORTA
	clrf PORTA

;;;; generated code for Loop1
_loop_1:

;;; SET::ASSIGN::vic_el_01::_vic_tmp_00

	movwf DIGIT
	andlw VIC_TBLSZ_LED7 - 1
	call _table_led7
	movwf VIC_EL_01

	;; moving VIC_EL_01 to PORTC
	movf VIC_EL_01, W
	movwf PORTC

	;; increments DIGIT in place
	;; increment byte[0]
	incf DIGIT, F

;;; SET::BAND_ASSIGN::digit::15

	;; perform DIGIT & 0x0F and move into W
	movlw 0x0F
	andwf DIGIT, W

	movwf DIGIT

	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
_table_led7:
	addwf PCL, F
	dt 0x3F
	dt 0x06
	dt 0x5B
	dt 0x4F
	dt 0x66
	dt 0x6D
	dt 0x7D
	dt 0x07
	dt 0x7F
	dt 0x67
	dt 0x77
	dt 0x7C
	dt 0x58
	dt 0x5E
	dt 0x79
	dt 0x71

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
