use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

Main {
    digital_output PORTC;
    Loop {
        $dummy = 0xFF;
        while $dummy != 0 {
            $dummy >>= 1;
            write PORTC, 1;
            if $dummy <= 0x0F {
                break;
            }
        }
        while $dummy > 0 {
            $dummy >>= 1;
            write PORTC, 3;
            continue;
        }
        if $dummy == TRUE {
            write PORTC, 2;
            break;
        } else {
            write PORTC, 4;
            continue;
        }
    }
    # we have broken from the loop
    while TRUE {
        write PORTC, 0xFF;
    }
}
...

my $output = << '...';
;;;; generated code for PIC header file
#include <p16f690.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
DUMMY res 1

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

;;;; generated code for Loop1
_loop_1:

	;; moves 255 (0xFF) to DUMMY
    banksel DUMMY
	movlw 0xFF
	movwf DUMMY

_start_conditional_1:
	bcf STATUS, Z
	movf DUMMY, W
	xorlw 0x00
	btfss STATUS, Z ;; dummy != 0 ?
	goto _true_2
	goto _end_conditional_1
_end_conditional_1:


_start_conditional_2:
	;; perform check for 0x00 < DUMMY or DUMMY > 0x00
	bcf STATUS, C
	movf DUMMY, W
	sublw 0x00
	btfsc STATUS, C ;; W(DUMMY) > k(0x00) => C = 0
	goto _end_conditional_2
	goto _true_4
_end_conditional_2:


_start_conditional_3:
	bcf STATUS, Z
	movf DUMMY, W
	xorlw 0x01
	btfss STATUS, Z ;; dummy == 1 ?
	goto _false_6
	goto _true_5
_end_conditional_3:


	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_start_conditional_4:
	goto _true_7
	goto _end_conditional_4
_end_conditional_4:
_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
;;;; generated code for False6
_false_6:

	;; moves 4 (0x04) to PORTC
    banksel PORTC
	movlw 0x04
	movwf PORTC

	goto _loop_1 ;; go back to start of conditional

	goto _end_conditional_3;; go back to end of conditional

;;;; end of _false_6
;;;; generated code for True2
_true_2:

	;;;; perform DUMMY >> 1
    bcf STATUS, C
	rrf DUMMY, W
    btfsc STATUS, C
    bcf DUMMY, 7
	movwf DUMMY

	;; moves 1 (0x01) to PORTC
    banksel PORTC
	movlw 0x01
	movwf PORTC

_start_conditional_0:
	;; perform check for 0x0F >= DUMMY or DUMMY <= 0x0F
	bcf STATUS, C
	movf DUMMY, W
	sublw 0x0F
	btfss STATUS, C ;; W(DUMMY) <= k(0x0F) => C = 1
	goto _end_conditional_0
	goto _true_3
_end_conditional_0:


	goto _start_conditional_1 ;; go back to start of conditional

;;;; end of _true_2
;;;; generated code for True3
_true_3:

	goto _end_conditional_1;; break from the conditional

	goto _end_conditional_0;; go back to end of conditional

;;;; end of _true_3
;;;; generated code for True4
_true_4:

	;;;; perform DUMMY >> 1
    bcf STATUS, C
	rrf DUMMY, W
    btfsc STATUS, C
    bcf DUMMY, 7
	movwf DUMMY

	;; moves 3 (0x03) to PORTC
    banksel PORTC
	movlw 0x03
	movwf PORTC

	goto _start_conditional_2 ;; go back to start of conditional

	goto _start_conditional_2 ;; go back to start of conditional

;;;; end of _true_4
;;;; generated code for True5
_true_5:

	;; moves 2 (0x02) to PORTC
    banksel PORTC
	movlw 0x02
	movwf PORTC

	goto _end_loop_1;; break from the conditional

	goto _end_conditional_3;; go back to end of conditional

;;;; end of _true_5
;;;; generated code for True7
_true_7:

	;; moves 255 (0xFF) to PORTC
    banksel PORTC
	movlw 0xFF
	movwf PORTC

	goto _start_conditional_4 ;; go back to start of conditional

;;;; end of _true_7


;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
