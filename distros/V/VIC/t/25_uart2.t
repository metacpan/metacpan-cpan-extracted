use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

Main {
    setup UART, 9600; # set up USART for transmit
    write UART, "Hello World!\n";
    write UART, "100";
    write UART, 100;
    $myvar = "Bye World!\n";
    write UART, $myvar;
    $myvar2 = 100;
    write UART, $myvar2;
}

Simulator {
    attach UART, 9600, 'loopback';
    stop_after 1s;
    log UART;
    scope UART;
    autorun;
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>
;;;; generated code for gpsim header file
#include <coff.inc>

;;;; generated code for variables
GLOBAL_VAR_UDATA udata
MYVAR res 0x0D; allocate memory for MYVAR
VIC_STRSZ_MYVAR equ 0x0C; VIC_STRSZ_MYVAR is length of _vic_str_02
MYVAR2 res 1

;;;; for m_op_assign_str
VIC_VAR_ASSIGN_STRIDX res 1
VIC_VAR_ASSIGN_STRLEN res 1


;;;;;;; USART I/O VARS ;;;;;;
VIC_VAR_USART_UDATA udata
VIC_VAR_USART_WLEN res 1
VIC_VAR_USART_WIDX res 1
VIC_VAR_USART_RLEN res 1
VIC_VAR_USART_RIDX res 1


;;;; generated code for macros
m_op_assign_str macro dvar, dlen, cvar, clen
	local _op_assign_str_loop_0
	local _op_assign_str_loop_1
	banksel VIC_VAR_ASSIGN_STRLEN
if dlen > clen
	movlw clen
else
	movlw dlen
endif
	movwf VIC_VAR_ASSIGN_STRLEN
	banksel dvar
	movlw (dvar - 1)
	movwf FSR
	banksel VIC_VAR_ASSIGN_STRIDX
	clrf VIC_VAR_ASSIGN_STRIDX
_op_assign_str_loop_0:
	movf VIC_VAR_ASSIGN_STRIDX, W
	call cvar
	incf FSR, F
	movwf INDF
	banksel VIC_VAR_ASSIGN_STRIDX
	incf VIC_VAR_ASSIGN_STRIDX, F
	bcf STATUS, Z
	bcf STATUS, C
	movf VIC_VAR_ASSIGN_STRIDX, W
	subwf VIC_VAR_ASSIGN_STRLEN, W
	;; W == 0
	btfsc STATUS, Z
	goto _op_assign_str_loop_1
	goto _op_assign_str_loop_0
_op_assign_str_loop_1:
	nop
	endm

m_op_nullify_str macro dvar, dlen, didx
	local _op_nullify_str_loop_0
	local _op_nullify_str_loop_1
	banksel VIC_VAR_ASSIGN_STRLEN
	movlw dlen
	movwf VIC_VAR_ASSIGN_STRLEN
	banksel dvar
	movlw (dvar - 1)
	movwf FSR
	banksel VIC_VAR_ASSIGN_STRIDX
	clrf VIC_VAR_ASSIGN_STRIDX
_op_nullify_str_loop_0:
	clrw
	incf FSR, F
	movwf INDF
	banksel VIC_VAR_ASSIGN_STRIDX
	incf VIC_VAR_ASSIGN_STRIDX, F
	bcf STATUS, Z
	bcf STATUS, C
	movf VIC_VAR_ASSIGN_STRIDX, W
	subwf VIC_VAR_ASSIGN_STRLEN, W
	;; W == 0
	btfsc STATUS, Z
	goto _op_nullify_str_loop_1
	goto _op_nullify_str_loop_0
_op_nullify_str_loop_1:
	banksel didx
	clrf didx
	endm

m_usart_write_byte macro wvar
	banksel wvar 
	movf wvar, W
	banksel TXREG
	movwf TXREG
	banksel TXSTA
	btfss TXSTA, TRMT
	goto $ - 1
	endm

m_usart_write_bytes macro wvar, wlen
	local _usart_write_bytes_loop_0
	local _usart_write_bytes_loop_1
	banksel VIC_VAR_USART_WLEN
	movlw (wlen - 1)
	movwf VIC_VAR_USART_WLEN
	clrf VIC_VAR_USART_WIDX
	banksel wvar
	movlw (wvar - 1) ;; load address into FSR
	movwf FSR
_usart_write_bytes_loop_0:
	incf FSR, F  ;; increment the FSR pointer
	movf INDF, W ;; load byte into register
	banksel TXREG
	movwf TXREG
	banksel TXSTA
	btfss TXSTA, TRMT
	goto $ - 1
	banksel VIC_VAR_USART_WIDX
	incf VIC_VAR_USART_WIDX, F
	bcf STATUS, Z
	bcf STATUS, C
	movf VIC_VAR_USART_WIDX, W
	subwf VIC_VAR_USART_WLEN, W
	;; W == 0
	btfsc STATUS, Z
	goto _usart_write_bytes_loop_1
	goto _usart_write_bytes_loop_0
_usart_write_bytes_loop_1:
	banksel TXSTA
	btfss TXSTA, TRMT
	goto $ - 1
	banksel VIC_VAR_USART_WIDX
	clrf VIC_VAR_USART_WIDX
	clrf VIC_VAR_USART_WLEN
	endm

m_usart_write_bytetbl macro tblentry, wlen
	local _usart_write_bytetbl_loop_0
	local _usart_write_bytetbl_loop_1
	banksel VIC_VAR_USART_WLEN
	movlw wlen
	movwf VIC_VAR_USART_WLEN
	banksel VIC_VAR_USART_WIDX
	clrf VIC_VAR_USART_WIDX
_usart_write_bytetbl_loop_0:
	movf VIC_VAR_USART_WIDX, W
	call tblentry
	banksel TXREG
	movwf TXREG
	banksel TXSTA
	btfss TXSTA, TRMT
	goto $ - 1
	banksel VIC_VAR_USART_WIDX
	incf VIC_VAR_USART_WIDX, F
	bcf STATUS, Z
	bcf STATUS, C
	movf VIC_VAR_USART_WIDX, W
	subwf VIC_VAR_USART_WLEN, W
	;; W == 0
	btfsc STATUS, Z
	goto _usart_write_bytetbl_loop_1
	goto _usart_write_bytetbl_loop_0
_usart_write_bytetbl_loop_1:
	;; finish the sending
	banksel TXSTA
	btfss TXSTA, TRMT
	goto $ - 1
	banksel VIC_VAR_USART_WIDX
	clrf VIC_VAR_USART_WIDX
	clrf VIC_VAR_USART_WLEN
	endm



	__config (_BOR_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF & _INTRC_OSC_CLKOUT & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF)


	org 0

;;;; generated common code for the Simulator
	.sim "module library libgpsim_modules"
	.sim "p16f690.xpos = 200"
	.sim "p16f690.ypos = 200"
	.sim "p16f690.frequency = 4000000"

;;;; generated code for Simulator
	.sim "module load usart U0"
	.sim "node TX_U0"
	.sim "node RX_U0"
	.sim "attach TX_U0 portb7 U0.RXPIN"
	.sim "attach RX_U0 portb5 U0.TXPIN"
	.sim "U0.txbaud = 9600"
	.sim "U0.rxbaud = 9600"
	.sim "U0.xpos = 500"
	.sim "U0.ypos = 50"
	.sim "U0.loop = true"

	.sim "break c 10000000"

	.sim "log r portb"
	.sim "log w portb"

	.sim "scope.ch0 = \"portb5\""
	.sim "scope.ch1 = \"portb7\""

	;;;; will autorun on start
	.sim "run"




;;;; generated code for Main
_start:

;;;Desired Baud: 9600
;;;Calculated Baud: 9615.3846
;;;Error: 0.160256%
;;;SPBRG: 25
;;;BRG16: 0
;;;BRGH: 1
	banksel BAUDCTL
	bcf BAUDCTL, BRG16
	banksel TXSTA
	bsf TXSTA, BRGH
	banksel SPBRG
	movlw 0x00
	movwf SPBRGH
	movlw 0x19
	movwf SPBRG

	banksel TXSTA
	;; asynchronous operation
	bcf TXSTA, SYNC
	;; transmit enable
	bsf TXSTA, TXEN
	banksel RCSTA
	;; serial port enable
	bsf RCSTA, SPEN
	;; continuous receive enable
	bsf RCSTA, CREN
	banksel ANSELH
	bcf ANSELH, ANS11



;;; sending the string 'Hello World!\n' to UART
;;;; byte array has length 0x0D
	m_usart_write_bytetbl _vic_str_00, 0x0D

;;; sending the string '100' to UART
;;;; byte array has length 0x03
	m_usart_write_bytetbl _vic_str_01, 0x03

;;; sending the number '100' to UART in big-endian mode
;;;; byte array has length 0x01
	m_usart_write_bytetbl _vic_bytes_0x64, 0x01

	;;;; moving contents of _vic_str_02 into MYVAR with bounds checking
	m_op_assign_str MYVAR, VIC_STRSZ_MYVAR, _vic_str_02, 0x0C

;;; sending contents of the variable 'MYVAR' of size 'VIC_STRSZ_MYVAR' to UART
	m_usart_write_bytes MYVAR, VIC_STRSZ_MYVAR

	;; moves 100 (0x64) to MYVAR2
	banksel MYVAR2
	movlw 0x64
	movwf MYVAR2

;;; sending the variable 'myvar2' to UART
	m_usart_write_byte MYVAR2

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
	;; storing string 'Bye World!\n'
_vic_str_02:
	addwf PCL, F
	dt 0x42,0x79,0x65,0x20,0x57,0x6F,0x72,0x6C,0x64,0x21,0x0A,0x00
	;;storing string 'Hello World!\n'
_vic_str_00:
	addwf PCL, F
	dt 0x48,0x65,0x6C,0x6C,0x6F,0x20,0x57,0x6F,0x72,0x6C,0x64,0x21,0x0A,0x00
	;;storing string '100'
_vic_str_01:
	addwf PCL, F
	dt 0x31,0x30,0x30,0x00
	;;storing number 100
_vic_bytes_0x64:
	addwf PCL, F
	dt 0x64,0x00

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
