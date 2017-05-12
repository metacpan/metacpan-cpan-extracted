use Test::More;
use t::TestVIC tests => 4, debug => 0;

sub get_input {
    my $type = shift;
    my %pwm_code = (
        single => "pwm_single 1220Hz, 20%, CCP1;",
        half => "pwm_halfbridge 1220Hz, 20%, 4us;",
        full_forward => "pwm_fullbridge 'forward', 1220Hz, 20%;",
        full_reverse => "pwm_fullbridge 'reverse', 1220Hz, 20%;",
    );
    note("Looking for input for $type");
    note("PWM vic code: $pwm_code{$type}");
    return << "...";
PIC P16F690;

Main {
    digital_output RC0;
    # arg1 - pwm frequency
    # arg2 - duty cycle ratio in percentage
    $pwm_code{$type}
    Loop {
        write RC0, CCP1;
    }
}

Simulator {
    attach_led CCP1;
    attach_led RC0;
    stop_after 20s;
    logfile "pwm.lxt";
    log CCP1;
    scope CCP1, RC0;
    autorun;
}
...
}

sub get_output {
    my $type = shift;
    note("Looking for output for $type");
    return get_pwm_single() if $type eq 'single';
    return get_pwm_half() if $type eq 'half';
    return get_pwm_full_forward() if $type eq 'full_forward';
    return get_pwm_full_reverse() if $type eq 'full_reverse';
    return '';
}

foreach (qw(single half full_forward full_reverse)) {
    compiles_ok(get_input($_), get_output($_));
}

sub get_pwm_single {
    return << '....';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables

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
	.sim "node ccp1led"
	.sim "attach ccp1led portc5 L0.in"

	.sim "module load led L1"
	.sim "L1.xpos = 100"
	.sim "L1.ypos = 100"
	.sim "L1.color = red"
	.sim "node rc0led"
	.sim "attach rc0led portc0 L1.in"

	.sim "break c 200000000"

	.sim "log lxt pwm.lxt"

	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"portc5\""
	.sim "scope.ch1 = \"portc0\""

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

;;; PWM Type: single
;;; PWM Frequency = 1220 Hz
;;; Duty Cycle = 20 / 100
;;; CCPR1L:CCP1CON<5:4> = 164
;;; CCPR1L = 0x29
;;; CCP1CON = b'00001100'
;;; T2CON = b'00000101'
;;; PR2 = 0xCB
;;; PSTRCON = b'00010001'
;;; PWM1CON = 0x80
;;; Prescaler = 4
;;; Fosc = 4000000
;;; disable the PWM output driver for CCP1 by setting the associated TRIS bit
	banksel TRISC
	bsf TRISC, TRISC5

;;; set PWM period by loading PR2
	banksel PR2
	movlw 0xCB
	movwf PR2
;;; configure the CCP module for the PWM mode by setting CCP1CON
	banksel CCP1CON
	movlw b'00001100'
	movwf CCP1CON
;;; set PWM duty cycle
	movlw 0x29
	movwf CCPR1L
;;; configure and start TMR2
;;; - clear TMR2IF flag of PIR1 register
	banksel PIR1
	bcf PIR1, TMR2IF
	movlw b'00000101'
	movwf T2CON
;;; enable PWM output after a new cycle has started
	btfss PIR1, TMR2IF
	goto $ - 1
	bcf PIR1, TMR2IF
;;; enable CCP1 pin output driver by clearing the associated TRIS bit
	banksel PSTRCON
	movlw b'00010001'
	movwf PSTRCON

;;; disable auto-shutdown mode
	banksel ECCPAS
	clrf ECCPAS
;;; set PWM1CON if half bridge mode
	banksel PWM1CON
	movlw 0x80
	movwf PWM1CON
	banksel TRISC
	bcf TRISC, TRISC5


;;;; generated code for Loop1
_loop_1:

	btfss PORTC, RC5
	bcf PORTC, RC0
	btfsc PORTC, RC5
	bsf PORTC, RC0

	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
....
}

sub get_pwm_half {
    return << '....';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables

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
	.sim "node ccp1led"
	.sim "attach ccp1led portc5 L0.in"

	.sim "module load led L1"
	.sim "L1.xpos = 100"
	.sim "L1.ypos = 100"
	.sim "L1.color = red"
	.sim "node rc0led"
	.sim "attach rc0led portc0 L1.in"

	.sim "break c 200000000"

	.sim "log lxt pwm.lxt"

	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"portc5\""
	.sim "scope.ch1 = \"portc0\""

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

;;; PWM Type: half
;;; PWM Frequency = 1220 Hz
;;; Duty Cycle = 20 / 100
;;; CCPR1L:CCP1CON<5:4> = 164
;;; CCPR1L = 0x29
;;; CCP1CON = b'10001100'
;;; T2CON = b'00000101'
;;; PR2 = 0xCB
;;; PSTRCON = b'00010000'
;;; PWM1CON = 0x84
;;; Prescaler = 4
;;; Fosc = 4000000
;;; disable the PWM output driver for P1A P1B by setting the associated TRIS bit
	banksel TRISC
	bsf TRISC, TRISC4
	bsf TRISC, TRISC5

;;; set PWM period by loading PR2
	banksel PR2
	movlw 0xCB
	movwf PR2
;;; configure the CCP module for the PWM mode by setting CCP1CON
	banksel CCP1CON
	movlw b'10001100'
	movwf CCP1CON
;;; set PWM duty cycle
	movlw 0x29
	movwf CCPR1L
;;; configure and start TMR2
;;; - clear TMR2IF flag of PIR1 register
	banksel PIR1
	bcf PIR1, TMR2IF
	movlw b'00000101'
	movwf T2CON
;;; enable PWM output after a new cycle has started
	btfss PIR1, TMR2IF
	goto $ - 1
	bcf PIR1, TMR2IF
;;; enable P1A P1B pin output driver by clearing the associated TRIS bit

;;; disable auto-shutdown mode
	banksel ECCPAS
	clrf ECCPAS
;;; set PWM1CON if half bridge mode
	banksel PWM1CON
	movlw 0x84
	movwf PWM1CON
	banksel TRISC
	bcf TRISC, TRISC4
	bcf TRISC, TRISC5


;;;; generated code for Loop1
_loop_1:

	btfss PORTC, RC5
	bcf PORTC, RC0
	btfsc PORTC, RC5
	bsf PORTC, RC0

	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
....
}

sub get_pwm_full_forward {
    return << '....';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables

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
	.sim "node ccp1led"
	.sim "attach ccp1led portc5 L0.in"

	.sim "module load led L1"
	.sim "L1.xpos = 100"
	.sim "L1.ypos = 100"
	.sim "L1.color = red"
	.sim "node rc0led"
	.sim "attach rc0led portc0 L1.in"

	.sim "break c 200000000"

	.sim "log lxt pwm.lxt"

	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"portc5\""
	.sim "scope.ch1 = \"portc0\""

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

;;; PWM Type: full_forward
;;; PWM Frequency = 1220 Hz
;;; Duty Cycle = 20 / 100
;;; CCPR1L:CCP1CON<5:4> = 164
;;; CCPR1L = 0x29
;;; CCP1CON = b'01001100'
;;; T2CON = b'00000101'
;;; PR2 = 0xCB
;;; PSTRCON = b'00010000'
;;; PWM1CON = 0x80
;;; Prescaler = 4
;;; Fosc = 4000000
;;; disable the PWM output driver for P1A P1B P1C P1D by setting the associated TRIS bit
	banksel TRISC
	bsf TRISC, TRISC2
	bsf TRISC, TRISC3
	bsf TRISC, TRISC4
	bsf TRISC, TRISC5

;;; set PWM period by loading PR2
	banksel PR2
	movlw 0xCB
	movwf PR2
;;; configure the CCP module for the PWM mode by setting CCP1CON
	banksel CCP1CON
	movlw b'01001100'
	movwf CCP1CON
;;; set PWM duty cycle
	movlw 0x29
	movwf CCPR1L
;;; configure and start TMR2
;;; - clear TMR2IF flag of PIR1 register
	banksel PIR1
	bcf PIR1, TMR2IF
	movlw b'00000101'
	movwf T2CON
;;; enable PWM output after a new cycle has started
	btfss PIR1, TMR2IF
	goto $ - 1
	bcf PIR1, TMR2IF
;;; enable P1A P1B P1C P1D pin output driver by clearing the associated TRIS bit

;;; disable auto-shutdown mode
	banksel ECCPAS
	clrf ECCPAS
;;; set PWM1CON if half bridge mode
	banksel PWM1CON
	movlw 0x80
	movwf PWM1CON
	banksel TRISC
	bcf TRISC, TRISC2
	bcf TRISC, TRISC3
	bcf TRISC, TRISC4
	bcf TRISC, TRISC5


;;;; generated code for Loop1
_loop_1:

	btfss PORTC, RC5
	bcf PORTC, RC0
	btfsc PORTC, RC5
	bsf PORTC, RC0

	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
....
}

sub get_pwm_full_reverse {
    return << '....'
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables

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
	.sim "node ccp1led"
	.sim "attach ccp1led portc5 L0.in"

	.sim "module load led L1"
	.sim "L1.xpos = 100"
	.sim "L1.ypos = 100"
	.sim "L1.color = red"
	.sim "node rc0led"
	.sim "attach rc0led portc0 L1.in"

	.sim "break c 200000000"

	.sim "log lxt pwm.lxt"

	.sim "log r portc"
	.sim "log w portc"

	.sim "scope.ch0 = \"portc5\""
	.sim "scope.ch1 = \"portc0\""

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

;;; PWM Type: full_reverse
;;; PWM Frequency = 1220 Hz
;;; Duty Cycle = 20 / 100
;;; CCPR1L:CCP1CON<5:4> = 164
;;; CCPR1L = 0x29
;;; CCP1CON = b'11001100'
;;; T2CON = b'00000101'
;;; PR2 = 0xCB
;;; PSTRCON = b'00010000'
;;; PWM1CON = 0x80
;;; Prescaler = 4
;;; Fosc = 4000000
;;; disable the PWM output driver for P1A P1B P1C P1D by setting the associated TRIS bit
	banksel TRISC
	bsf TRISC, TRISC2
	bsf TRISC, TRISC3
	bsf TRISC, TRISC4
	bsf TRISC, TRISC5

;;; set PWM period by loading PR2
	banksel PR2
	movlw 0xCB
	movwf PR2
;;; configure the CCP module for the PWM mode by setting CCP1CON
	banksel CCP1CON
	movlw b'11001100'
	movwf CCP1CON
;;; set PWM duty cycle
	movlw 0x29
	movwf CCPR1L
;;; configure and start TMR2
;;; - clear TMR2IF flag of PIR1 register
	banksel PIR1
	bcf PIR1, TMR2IF
	movlw b'00000101'
	movwf T2CON
;;; enable PWM output after a new cycle has started
	btfss PIR1, TMR2IF
	goto $ - 1
	bcf PIR1, TMR2IF
;;; enable P1A P1B P1C P1D pin output driver by clearing the associated TRIS bit

;;; disable auto-shutdown mode
	banksel ECCPAS
	clrf ECCPAS
;;; set PWM1CON if half bridge mode
	banksel PWM1CON
	movlw 0x80
	movwf PWM1CON
	banksel TRISC
	bcf TRISC, TRISC2
	bcf TRISC, TRISC3
	bcf TRISC, TRISC4
	bcf TRISC, TRISC5


;;;; generated code for Loop1
_loop_1:

	btfss PORTC, RC5
	bcf PORTC, RC0
	btfsc PORTC, RC5
	bsf PORTC, RC0

	goto _loop_1 ;;;; end of _loop_1

_end_loop_1:

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions

;;;; generated code for end-of-file
	end
....
}
