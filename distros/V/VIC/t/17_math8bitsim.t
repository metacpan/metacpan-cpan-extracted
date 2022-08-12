use Test::Lib;
use Test::VIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

pragma variable bits = 8;
pragma variable export;

Main {
    $var1 = 12345;
    sim_assert $var1 == 57, "12345 was placed as 57 due to 8-bit mode";
    $var2 = 113;
    $var3 = $var2 + $var1;
    sim_assert $var3 == 170, "57 + 113 = 170";
    $var3 = $var2 - $var1;
    sim_assert $var3 == 56, "113 - 57 = 56";
    $var3 = $var2 * $var1;
    sim_assert $var3 == 41, "113 * 57 = 41";
    $var2 = $var2 * 5;
    sim_assert $var2 == 53, "113 * 5 = 565 => 53 in 8-bit mode";
    $var3 = $var2 / $var1;
    sim_assert $var3 == 0, "53 / 57 = 0 in integer mathematics";
    $var3 = $var2 % $var1;
    sim_assert $var3 == 53, "53 % 57 = 53";
    --$var3;
    sim_assert $var3 == 52, "--53 = 52";
    ++$var3;
    sim_assert $var3 == 53, "++52 = 53";
    $var4 = 64;
    $var4 -= $var1;
    sim_assert $var4 == 7, "64 - 57 = 7";
    $var3 *= 3;
    sim_assert $var3 == 159, "53 * 3 = 159";
    $var2 /= 5;
    sim_assert $var2 == 10, "53 / 5 = 10";
    $var4 %= $var2;
    sim_assert $var4 == 7, "7 % 10 = 7";
    $var4 = 64;
    $var4 ^= 0xFF;
    sim_assert $var4 == 0xBF, "64 ^ 0xFF = 0xBF";
    $var4 |= 0x80;
    sim_assert $var4 == 0xBF, "0xBF | 0x80 = 0xBF";
    $var4 &= 0xAA;
    sim_assert $var4 == 0xAA, "0xBF & 0xAA = 0xAA";
    $var4 = $var4 << 1;
    sim_assert $var4 == 84, "0xAA << 1 = 340 which is 84 in 8-bit mode";
    $var4 = $var4 >> 1;
    sim_assert $var4 == 42, "84 >> 1 = 42";
    $var4 <<= 1;
    sim_assert $var4 == 84, "42 << 1 = 84";
    $var4 >>= 1;
    sim_assert $var4 == 42, "84 >> 1 = 42";
    $var5 = $var1 - $var2 + $var3 * ($var4 + 8) / $var1;
    sim_assert $var5 == 47, "57 - 10 + ((159 * (42 + 8)) & 0xFF) / 57";
    $var7 = 13;
    $var5 = ($var1 + (($var3 * ($var4 + $var7) + 5) + $var2));
    sim_assert $var5 == 113,
        "57 + (((159 * (42 + 13)) & 0xFF + 5) + 10) = 113";
    $var6 = 19;
    $var8 = ($var1 + $var2) - ($var3 * $var4) / ($var5 % $var6);
    sim_assert $var8 == 66, "(57 + 10) - ((159 * 42) & 0xFF) / (113 % 19)";
    # sqrt is a modifier
    $var3 = sqrt $var4;
    sim_assert $var3 == 6,
        "sqrt(42) = 6.4807 which is 6 in integer mathematics";
    sim_assert "*** Completed the simulation ***";
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
VAR1 res 1
VAR2 res 1
VAR3 res 1
VAR4 res 1
VAR5 res 1
VAR6 res 1
VAR7 res 1
VAR8 res 1
VIC_STACK res 5	;; temporary stack
	global VAR1, VAR2, VAR3, VAR4, VAR5, VAR6, VAR7, VAR8

;;;;;; VIC_VAR_DIVIDE VARIABLES ;;;;;;;

VIC_VAR_DIVIDE_UDATA udata
VIC_VAR_DIVISOR res 2
VIC_VAR_REMAINDER res 2
VIC_VAR_QUOTIENT res 2
VIC_VAR_BITSHIFT res 2
VIC_VAR_DIVTEMP res 1


;;;;;; VIC_VAR_MULTIPLY VARIABLES ;;;;;;;

VIC_VAR_MULTIPLY_UDATA udata
VIC_VAR_MULTIPLICAND res 2
VIC_VAR_MULTIPLIER res 2
VIC_VAR_PRODUCT res 2


;;;;;; VIC_VAR_SQRT VARIABLES ;;;;;;
VIC_VAR_SQRT_UDATA udata
VIC_VAR_SQRT_VAL res 2
VIC_VAR_SQRT_RES res 2
VIC_VAR_SQRT_SUM res 2
VIC_VAR_SQRT_ODD res 2
VIC_VAR_SQRT_TMP res 2


;;;; generated code for macros
;;;;;; Taken from Microchip PIC examples.
m_divide_internal macro
    local _m_divide_shiftuploop, _m_divide_loop, _m_divide_shift
    clrf VIC_VAR_QUOTIENT
    clrf VIC_VAR_QUOTIENT + 1
    clrf VIC_VAR_BITSHIFT + 1
    movlw 0x01
    movwf VIC_VAR_BITSHIFT
_m_divide_shiftuploop:
    bcf STATUS, C
    rlf VIC_VAR_DIVISOR, F
    rlf VIC_VAR_DIVISOR + 1, F
    bcf STATUS, C
    rlf VIC_VAR_BITSHIFT, F
    rlf VIC_VAR_BITSHIFT + 1, F
    btfss VIC_VAR_DIVISOR + 1, 7
    goto _m_divide_shiftuploop
_m_divide_loop:
    movf VIC_VAR_DIVISOR, W
    subwf VIC_VAR_REMAINDER, W
    movwf VIC_VAR_DIVTEMP
    movf VIC_VAR_DIVISOR + 1, W
    btfss STATUS, C
    addlw 0x01
    subwf VIC_VAR_REMAINDER + 1, W
    btfss STATUS, C
    goto _m_divide_shift
    movwf VIC_VAR_REMAINDER + 1
    movf VIC_VAR_DIVTEMP, W
    movwf VIC_VAR_REMAINDER
    movf VIC_VAR_BITSHIFT + 1, W
    addwf VIC_VAR_QUOTIENT + 1, F
    movf VIC_VAR_BITSHIFT, W
    addwf VIC_VAR_QUOTIENT, F
_m_divide_shift:
    bcf STATUS, C
    rrf VIC_VAR_DIVISOR + 1, F
    rrf VIC_VAR_DIVISOR, F
    bcf STATUS, C
    rrf VIC_VAR_BITSHIFT + 1, F
    rrf VIC_VAR_BITSHIFT, F
    btfss STATUS, C
    goto _m_divide_loop
    endm
;;;;;; v1 and v2 are variables
m_divide_2 macro v1, v2
    movf v1, W
    movwf VIC_VAR_REMAINDER
    clrf VIC_VAR_REMAINDER + 1
    movf v2, W
    movwf VIC_VAR_DIVISOR
    clrf VIC_VAR_DIVISOR + 1
    m_divide_internal
    movf VIC_VAR_QUOTIENT, W
    endm
;;;;;; v1 is literal and v2 is variable
m_divide_1a macro v1, v2
    movlw v1
    movwf VIC_VAR_REMAINDER
    clrf VIC_VAR_REMAINDER + 1
    movf v2, W
    movwf VIC_VAR_DIVISOR
    clrf VIC_VAR_DIVISOR + 1
    m_divide_internal
    movf VIC_VAR_QUOTIENT, W
    endm
;;;;;;; v2 is literal and v1 is variable
m_divide_1b macro v1, v2
    movf v1, W
    movwf VIC_VAR_REMAINDER
    clrf VIC_VAR_REMAINDER + 1
    movlw v2
    movwf VIC_VAR_DIVISOR
    clrf VIC_VAR_DIVISOR + 1
    m_divide_internal
    movf VIC_VAR_QUOTIENT, W
    endm
m_mod_2 macro v1, v2
    m_divide_2 v1, v2
    movf VIC_VAR_REMAINDER, W
    endm
;;;;;; v1 is literal and v2 is variable
m_mod_1a macro v1, v2
    m_divide_1a v1, v2
    movf VIC_VAR_REMAINDER, W
    endm
;;;;;;; v2 is literal and v1 is variable
m_mod_1b macro v1, v2
    m_divide_1b v1, v2
    movf VIC_VAR_REMAINDER, W
    endm

;;;;;; Taken from Microchip PIC examples.
;;;;;; multiply v1 and v2 using shifting. multiplication of 8-bit values is done
;;;;;; using 16-bit variables. v1 is a variable and v2 is a constant
m_multiply_internal macro
    local _m_multiply_loop_0, _m_multiply_skip
    clrf VIC_VAR_PRODUCT
    clrf VIC_VAR_PRODUCT + 1
_m_multiply_loop_0:
    rrf VIC_VAR_MULTIPLICAND, F
    btfss STATUS, C
    goto _m_multiply_skip
    movf VIC_VAR_MULTIPLIER + 1, W
    addwf VIC_VAR_PRODUCT + 1, F
    movf VIC_VAR_MULTIPLIER, W
    addwf VIC_VAR_PRODUCT, F
    btfsc STATUS, C
    incf VIC_VAR_PRODUCT + 1, F
_m_multiply_skip:
    bcf STATUS, C
    rlf VIC_VAR_MULTIPLIER, F
    rlf VIC_VAR_MULTIPLIER + 1, F
    movf VIC_VAR_MULTIPLICAND, F
    btfss STATUS, Z
    goto _m_multiply_loop_0
    movf VIC_VAR_PRODUCT, W
    endm
;;;;;;; v1 is variable and v2 is literal
m_multiply_1 macro v1, v2
    movf v1, W
    movwf VIC_VAR_MULTIPLIER
    clrf VIC_VAR_MULTIPLIER + 1
    movlw v2
    movwf VIC_VAR_MULTIPLICAND
    clrf VIC_VAR_MULTIPLICAND + 1
    m_multiply_internal
    endm
;;;;;; multiply v1 and v2 using shifting. multiplication of 8-bit values is done
;;;;;; using 16-bit variables. v1 and v2 are variables
m_multiply_2 macro v1, v2
    movf v1, W
    movwf VIC_VAR_MULTIPLIER
    clrf VIC_VAR_MULTIPLIER + 1
    movf v2, W
    movwf VIC_VAR_MULTIPLICAND
    clrf VIC_VAR_MULTIPLICAND + 1
    m_multiply_internal
    endm

;;;;;; Taken from Microchip PIC examples.
;;;;;; reverse of Finite Difference Squaring
m_sqrt_internal macro
    local _m_sqrt_loop, _m_sqrt_loop_break
    movlw 0x01
    movwf VIC_VAR_SQRT_ODD
    clrf VIC_VAR_SQRT_ODD + 1
    clrf VIC_VAR_SQRT_RES
    clrf VIC_VAR_SQRT_RES + 1
    clrf VIC_VAR_SQRT_SUM
    clrf VIC_VAR_SQRT_SUM + 1
    clrf VIC_VAR_SQRT_TMP
    clrf VIC_VAR_SQRT_TMP + 1
_m_sqrt_loop:
    movf VIC_VAR_SQRT_SUM + 1, W
    addwf VIC_VAR_SQRT_ODD + 1, W
    movwf VIC_VAR_SQRT_TMP + 1
    movf VIC_VAR_SQRT_SUM, W
    addwf VIC_VAR_SQRT_ODD, W
    movwf VIC_VAR_SQRT_TMP
    btfsc STATUS, C
    incf VIC_VAR_SQRT_TMP + 1, F
    movf VIC_VAR_SQRT_TMP, W
    subwf VIC_VAR_SQRT_VAL, W
    movf VIC_VAR_SQRT_TMP + 1, W
    btfss STATUS, C
    addlw 0x01
    subwf VIC_VAR_SQRT_VAL + 1, W
    btfss STATUS, C
    goto _m_sqrt_loop_break
    movf VIC_VAR_SQRT_TMP + 1, W
    movwf VIC_VAR_SQRT_SUM + 1
    movf VIC_VAR_SQRT_TMP, W
    movwf VIC_VAR_SQRT_SUM
    movlw 0x02
    addwf VIC_VAR_SQRT_ODD, F
    btfsc STATUS, C
    incf VIC_VAR_SQRT_ODD + 1, F
    incf VIC_VAR_SQRT_RES, F
    btfsc STATUS, Z
    incf VIC_VAR_SQRT_RES + 1, F
    goto _m_sqrt_loop
_m_sqrt_loop_break:
    endm
m_sqrt_8bit macro v1
    movf v1, W
    movwf VIC_VAR_SQRT_VAL
    clrf VIC_VAR_SQRT_VAL + 1
    m_sqrt_internal
    movf VIC_VAR_SQRT_RES, W
    endm
m_sqrt_16bit macro v1
    movf high v1, W
    movwf VIC_VAR_SQRT_VAL + 1
    movf low v1, W
    movwf VIC_VAR_SQRT_VAL
    m_sqrt_internal
    movf VIC_VAR_SQRT_RES, W
    endm



    __config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)



	org 0

;;;; generated common code for the Simulator
	.sim "module library libgpsim_modules"
	.sim "p16f690.xpos = 200"
	.sim "p16f690.ypos = 200"
	.sim "p16f690.frequency = 4000000"





;;;; generated code for Main
_start:

	;; moves 12345 (0x3039) to VAR1
	;; 12345 doesn't fit in 8-bits. Using 57 (0x39)
    banksel VAR1
	movlw 0x39
	movwf VAR1

	;; break if the condition evaluates to false
	.assert "VAR1 == 0x39, \"12345 was placed as 57 due to 8-bit mode\""
	nop ;; needed for the assert

	;; moves 113 (0x71) to VAR2
    banksel VAR2
	movlw 0x71
	movwf VAR2

	;; add VAR2 and VAR1 without affecting either
	movf VAR2, W
	addwf VAR1, W
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0xAA, \"57 + 113 = 170\""
	nop ;; needed for the assert

	;; perform VAR2 - VAR1 without affecting either
	movf VAR1, W
	subwf VAR2, W
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x38, \"113 - 57 = 56\""
	nop ;; needed for the assert

	;; perform VAR2 * VAR1 without affecting either
	m_multiply_2 VAR2, VAR1
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x29, \"113 * 57 = 41\""
	nop ;; needed for the assert

	;; perform VAR2 * 0x05 without affecting VAR2
	m_multiply_1 VAR2, 0x05
	movwf VAR2

	;; break if the condition evaluates to false
	.assert "VAR2 == 0x35, \"113 * 5 = 565 => 53 in 8-bit mode\""
	nop ;; needed for the assert

	;; perform VAR2 / VAR1 without affecting either
	m_divide_2 VAR2, VAR1
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x00, \"53 / 57 = 0 in integer mathematics\""
	nop ;; needed for the assert

	;; perform VAR2 / VAR1 without affecting either
	m_mod_2 VAR2, VAR1
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x35, \"53 % 57 = 53\""
	nop ;; needed for the assert

	;; decrements VAR3 in place
	;; decrement byte[0]
	decf VAR3, F

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x34, \"--53 = 52\""
	nop ;; needed for the assert

	;; increments VAR3 in place
	;; increment byte[0]
	incf VAR3, F

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x35, \"++52 = 53\""
	nop ;; needed for the assert

	;; moves 64 (0x40) to VAR4
    banksel VAR4
	movlw 0x40
	movwf VAR4

	;; perform VAR4 - VAR1 without affecting either
	movf VAR1, W
	subwf VAR4, W
	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0x07, \"64 - 57 = 7\""
	nop ;; needed for the assert

	;; perform VAR3 * 0x03 without affecting VAR3
	m_multiply_1 VAR3, 0x03
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x9F, \"53 * 3 = 159\""
	nop ;; needed for the assert

	;; perform VAR2 / 0x05 without affecting VAR2
	m_divide_1b VAR2, 0x05
	movwf VAR2

	;; break if the condition evaluates to false
	.assert "VAR2 == 0x0A, \"53 / 5 = 10\""
	nop ;; needed for the assert

	;; perform VAR4 / VAR2 without affecting either
	m_mod_2 VAR4, VAR2
	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0x07, \"7 % 10 = 7\""
	nop ;; needed for the assert

	;; moves 64 (0x40) to VAR4
    banksel VAR4
	movlw 0x40
	movwf VAR4

	;; perform VAR4 ^ 0xFF and move into W
	movlw 0xFF
	xorwf VAR4, W

	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0xBF, \"64 ^ 0xFF = 0xBF\""
	nop ;; needed for the assert

	;; perform VAR4 | 0x80 and move into W
	movlw 0x80
	iorwf VAR4, W

	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0xBF, \"0xBF | 0x80 = 0xBF\""
	nop ;; needed for the assert

	;; perform VAR4 & 0xAA and move into W
	movlw 0xAA
	andwf VAR4, W

	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0xAA, \"0xBF & 0xAA = 0xAA\""
	nop ;; needed for the assert

	;;;; perform VAR4 << 1
	bcf STATUS, C
	rlf VAR4, W
	btfsc STATUS, C
	bcf VAR4, 0
	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0x54, \"0xAA << 1 = 340 which is 84 in 8-bit mode\""
	nop ;; needed for the assert

	;;;; perform VAR4 >> 1
	bcf STATUS, C
	rrf VAR4, W
	btfsc STATUS, C
	bcf VAR4, 7
	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0x2A, \"84 >> 1 = 42\""
	nop ;; needed for the assert

	;;;; perform VAR4 << 1
	bcf STATUS, C
	rlf VAR4, W
	btfsc STATUS, C
	bcf VAR4, 0
	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0x54, \"42 << 1 = 84\""
	nop ;; needed for the assert

	;;;; perform VAR4 >> 1
	bcf STATUS, C
	rrf VAR4, W
	btfsc STATUS, C
	bcf VAR4, 7
	movwf VAR4

	;; break if the condition evaluates to false
	.assert "VAR4 == 0x2A, \"84 >> 1 = 42\""
	nop ;; needed for the assert

	;; add 0x08 and VAR4 without affecting VAR4
	movf VAR4, W
	addlw 0x08
	movwf VIC_STACK + 0

	;; perform VAR3 * VIC_STACK + 0 without affecting either
	m_multiply_2 VAR3, VIC_STACK + 0
	movwf VIC_STACK + 1

	;; perform VIC_STACK + 1 / VAR1 without affecting either
	m_divide_2 VIC_STACK + 1, VAR1
	movwf VIC_STACK + 2

	;; perform VAR1 - VAR2 without affecting either
	movf VAR2, W
	subwf VAR1, W
	movwf VIC_STACK + 3

	;; add VIC_STACK + 3 and VIC_STACK + 2 without affecting either
	movf VIC_STACK + 3, W
	addwf VIC_STACK + 2, W
	movwf VAR5

	;; break if the condition evaluates to false
	.assert "VAR5 == 0x2F, \"57 - 10 + ((159 * (42 + 8)) & 0xFF) / 57\""
	nop ;; needed for the assert

	;; moves 13 (0x0D) to VAR7
    banksel VAR7
	movlw 0x0D
	movwf VAR7

	;; add VAR4 and VAR7 without affecting either
	movf VAR4, W
	addwf VAR7, W
	movwf VIC_STACK + 0

	;; perform VAR3 * VIC_STACK + 0 without affecting either
	m_multiply_2 VAR3, VIC_STACK + 0
	movwf VIC_STACK + 1

	;; add 0x05 and VIC_STACK + 1 without affecting VIC_STACK + 1
	movf VIC_STACK + 1, W
	addlw 0x05
	movwf VIC_STACK + 2

	;; add VIC_STACK + 2 and VAR2 without affecting either
	movf VIC_STACK + 2, W
	addwf VAR2, W
	movwf VIC_STACK + 3

	;; add VAR1 and VIC_STACK + 3 without affecting either
	movf VAR1, W
	addwf VIC_STACK + 3, W
	movwf VAR5

	;; break if the condition evaluates to false
	.assert "VAR5 == 0x71, \"57 + (((159 * (42 + 13)) & 0xFF + 5) + 10) = 113\""
	nop ;; needed for the assert

	;; moves 19 (0x13) to VAR6
    banksel VAR6
	movlw 0x13
	movwf VAR6

	;; add VAR1 and VAR2 without affecting either
	movf VAR1, W
	addwf VAR2, W
	movwf VIC_STACK + 0

	;; perform VAR3 * VAR4 without affecting either
	m_multiply_2 VAR3, VAR4
	movwf VIC_STACK + 1

	;; perform VAR5 / VAR6 without affecting either
	m_mod_2 VAR5, VAR6
	movwf VIC_STACK + 2

	;; perform VIC_STACK + 1 / VIC_STACK + 2 without affecting either
	m_divide_2 VIC_STACK + 1, VIC_STACK + 2
	movwf VIC_STACK + 3

	;; perform VIC_STACK + 0 - VIC_STACK + 3 without affecting either
	movf VIC_STACK + 3, W
	subwf VIC_STACK + 0, W
	movwf VAR8

	;; break if the condition evaluates to false
	.assert "VAR8 == 0x42, \"(57 + 10) - ((159 * 42) & 0xFF) / (113 % 19)\""
	nop ;; needed for the assert

	;; perform sqrt(VAR4)
	m_sqrt_8bit VAR4
	movwf VAR3

	;; break if the condition evaluates to false
	.assert "VAR3 == 0x06, \"sqrt(42) = 6.4807 which is 6 in integer mathematics\""
	nop ;; needed for the assert

	;; break if the condition evaluates to false
	.assert "\"*** Completed the simulation ***\""
	nop ;; needed for the assert

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
