use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

Main {
    digital_output PORTC;
    $display = 0;    
    timer_enable TMR0, 4kHz;
    Loop {
        timer TMR0, Action {
            ++$display;
            write PORTC, $display;
        };
    }
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
DISPLAY res 1

;;;; generated code for macros



    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)


	org 0

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

	clrf DISPLAY

	banksel OPTION_REG
	clrw
	iorlw B'00000111'
	movwf OPTION_REG
	banksel TMR0
	clrf TMR0

;;;; generated code for Loop1
_loop_1:

	btfss INTCON, T0IF
    goto _end_action_2
	bcf INTCON, T0IF
	goto _action_2
_end_action_2:
    goto _loop_1
_end_loop_1:
_end_start:
    goto $

;;;; generated code for functions
;;;; generated code for Action2
_action_2:

	;; increments DISPLAY in place
	incf DISPLAY, F

	;; moves DISPLAY to PORTC
	movf  DISPLAY, W
	movwf PORTC
    goto _end_action_2;; from _action_2

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
