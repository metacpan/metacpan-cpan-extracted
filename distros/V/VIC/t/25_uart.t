use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

pragma UART baud = 9600; # set baud rate

Main {
    setup UART, 9600; # set up USART for transmit
    write UART, "Hello World!\n";
}

Simulator {
    attach UART, 9600;
    log UART;
    scope UART;
}
...

my $output = <<'...';
;;;; generated code for PIC header file
#include <p16f690.inc>
#include <coff.inc>

;;;; generated code for variables

;;;;;;; USART I/O VARS ;;;;;;
VIC_VAR_USART_UDATA udata
VIC_VAR_USART_WLEN res 1
VIC_VAR_USART_WIDX res 1
VIC_VAR_USART_RLEN res 1
VIC_VAR_USART_RIDX res 1


;;;; generated code for macros
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

    .sim "log r portb"
    .sim "log w portb"

    .sim "scope.ch0 = \"portb5\""
    .sim "scope.ch1 = \"portb7\""

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

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
	;;storing string 'Hello World!\n'
_vic_str_00:
	addwf PCL, F
	dt 0x48,0x65,0x6C,0x6C,0x6F,0x20,0x57,0x6F,0x72,0x6C,0x64,0x21,0x0A,0x00

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
