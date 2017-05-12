use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

Main {
    digital_output PORTC;
    $var1 = TRUE;
    $var2 = FALSE;
    Loop {
        if $var1 != FALSE && $var2 != FALSE {
            write PORTC, 1;
            $var1 = !$var2;
        } else if $var1 || $var2 {
            write PORTC, 2;
            $var2 = $var1;
        } else if !$var1 {
            write PORTC, 4;
            $var2 = !$var1;
        } else if $var2 {
            write PORTC, 4;
            $var2 = !$var1;
        } else {
            write PORTC, 8;
            $var1 = !$var2;
        }
        $var3 = 0xFF;
        while $var3 != 0 {
            $var3 >>= 1;
        }
    }
}
...

my $output = << '...';
;;;; generated code for PIC header file
#include <p16f690.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
VAR1 res 1
VAR2 res 1
VAR3 res 1
VIC_STACK res 4	;; temporary stack

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

	;; moves 1 (0x01) to VAR1
    banksel VAR1
	movlw 0x01
	movwf VAR1

	;; moves 0 (0x00) to VAR2
	clrf VAR2

;;;; generated code for Loop1
_loop_1:

_start_conditional_0:
	bcf STATUS, Z
	movf VAR1, W
	xorlw 0x00
	btfss STATUS, Z ;; var1 != 0 ?
	goto _end_conditional_0_0_t_0
	goto _end_conditional_0_0_f_0
_end_conditional_0_0_t_0:
	clrw
	goto _end_conditional_0_0_e_0
_end_conditional_0_0_f_0:
	movlw 0x01
_end_conditional_0_0_e_0:
	movwf VIC_STACK + 0


	bcf STATUS, Z
	movf VAR2, W
	xorlw 0x00
	btfss STATUS, Z ;; var2 != 0 ?
	goto _end_conditional_0_0_t_1
	goto _end_conditional_0_0_f_1
_end_conditional_0_0_t_1:
	clrw
	goto _end_conditional_0_0_e_1
_end_conditional_0_0_f_1:
	movlw 0x01
_end_conditional_0_0_e_1:
	movwf VIC_STACK + 1


	;; perform check for VIC_STACK + 0 && VIC_STACK + 1
	bcf STATUS, Z
	movf VIC_STACK + 0, W
	btfss STATUS, Z  ;; VIC_STACK + 0 is false if it is set else true
	goto _end_conditional_0_0_f_2
	movf VIC_STACK + 1, W
	btfss STATUS, Z ;; VIC_STACK + 1 is false if it is set else true
	goto _end_conditional_0_0_f_2
	goto _end_conditional_0_0_t_2
_end_conditional_0_0_f_2:
	clrw
	goto _end_conditional_0_0_e_2
_end_conditional_0_0_t_2:
	movlw 0x01
_end_conditional_0_0_e_2:
	movwf VIC_STACK + 2


	bcf STATUS, Z
	movf VIC_STACK + 2, W
	xorlw 0x01
	btfss STATUS, Z ;; VIC_STACK + 2 == 1 ?
	goto _end_conditional_0_0
	goto _true_2
_end_conditional_0_0:


	;; perform check for VAR1 || VAR2
	bcf STATUS, Z
	movf VAR1, W
	btfss STATUS, Z  ;; VAR1 is false if it is set else true
	goto _true_3
	movf VAR2, W
	btfsc STATUS, Z ;; VAR2 is false if it is set else true
	goto _end_conditional_0_1
	goto _true_3
_end_conditional_0_1:


	;;;; generate code for !VAR1
	movf VAR1, W
	btfss STATUS, Z
	goto $ + 3
	movlw 1
	goto $ + 2
	clrw
	movwf VIC_STACK + 0


	bcf STATUS, Z
	movf VIC_STACK + 0, W
	xorlw 0x01
	btfss STATUS, Z ;; VIC_STACK + 0 == 1 ?
	goto _end_conditional_0_2
	goto _true_4
_end_conditional_0_2:


	bcf STATUS, Z
	movf VAR2, W
	xorlw 0x01
	btfss STATUS, Z ;; var2 == 1 ?
	goto _false_6
	goto _true_5
_end_conditional_0_3:


_end_conditional_0:
	;; moves 255 (0xFF) to VAR3
    banksel VAR3
	movlw 0xFF
	movwf VAR3

_start_conditional_1:
	bcf STATUS, Z
	movf VAR3, W
	xorlw 0x00
	btfss STATUS, Z ;; var3 != 0 ?
	goto _true_7
	goto _end_conditional_1
_end_conditional_1:

	goto _loop_1
_end_loop_1:
_end_start:
    goto $

;;;; generated code for functions
;;;; generated code for False6
_false_6:

	;; moves 8 (0x08) to PORTC
    banksel PORTC
	movlw 0x08
	movwf PORTC

	;;;; generate code for !VAR2
	movf VAR2, W
	btfss STATUS, Z
	goto $ + 3
	movlw 1
	goto $ + 2
	clrw
	movwf VAR1


	goto _end_conditional_0;; go back to end of conditional

;;;; generated code for True2
_true_2:

	;; moves 1 (0x01) to PORTC
    banksel PORTC
	movlw 0x01
	movwf PORTC

	;;;; generate code for !VAR2
	movf VAR2, W
	btfss STATUS, Z
	goto $ + 3
	movlw 1
	goto $ + 2
	clrw
	movwf VAR1


	goto _end_conditional_0;; go back to end of conditional

;;;; generated code for True3
_true_3:

	;; moves 2 (0x02) to PORTC
    banksel PORTC
	movlw 0x02
	movwf PORTC

	;; moving VAR1 to VAR2
	movf VAR1, W
	movwf VAR2

	goto _end_conditional_0;; go back to end of conditional

;;;; generated code for True4
_true_4:

	;; moves 4 (0x04) to PORTC
    banksel PORTC
	movlw 0x04
	movwf PORTC

	;;;; generate code for !VAR1
	movf VAR1, W
	btfss STATUS, Z
	goto $ + 3
	movlw 1
	goto $ + 2
	clrw
	movwf VAR2


	goto _end_conditional_0;; go back to end of conditional

;;;; generated code for True5
_true_5:

	;; moves 4 (0x04) to PORTC
    banksel PORTC
	movlw 0x04
	movwf PORTC

	;;;; generate code for !VAR1
	movf VAR1, W
	btfss STATUS, Z
	goto $ + 3
	movlw 1
	goto $ + 2
	clrw
	movwf VAR2


	goto _end_conditional_0;; go back to end of conditional

;;;; generated code for True7
_true_7:

	;;;; perform VAR3 >> 1
    bcf STATUS, C
	rrf VAR3, W
    btfsc STATUS, C
    bcf VAR3, 7
	movwf VAR3

	goto _start_conditional_1;; go back to start of conditional



;;;; generated code for end-of-file
	end
...
compiles_ok($input, $output);
