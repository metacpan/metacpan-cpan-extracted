use Test::Lib;
use Test::VIC tests => 1, debug => 0;

my $input = <<'...';

PIC P16F690;

Main {
    setup UART, 9600; # set up USART for transmit
    $myvar2 = "";
    read UART, ISR {
        $myvar2 .= shift;
    };
    write UART, "Hello World!";
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
MYVAR2 res 0x20; allocate memory for MYVAR2
MYVAR2_IDX res 1; index for accessing MYVAR2 elements
VIC_STRSZ_MYVAR2 equ 0x20; VIC_STRSZ_MYVAR2 is length of MYVAR2

;;;; for m_op_assign_str/m_op_nullify_str/m_op_concat_byte
VIC_VAR_ASSIGN_STRIDX res 1
VIC_VAR_ASSIGN_STRLEN res 1


;;;;;;; USART I/O VARS ;;;;;;
VIC_VAR_USART_UDATA udata
VIC_VAR_USART_WLEN res 1
VIC_VAR_USART_WIDX res 1
VIC_VAR_USART_RLEN res 1
VIC_VAR_USART_RIDX res 1


cblock 0x70 ;; unbanked RAM that is common across all banks
ISR_STATUS
ISR_W
endc


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

m_op_concat_bytev macro dvar, dlen, didx, bvar
	local _op_concat_bytev_end
	;;;; check for space first and then add byte
	banksel didx
	movf didx, W
	banksel VIC_VAR_ASSIGN_STRIDX
	movwf VIC_VAR_ASSIGN_STRIDX
	movlw dlen
	movwf VIC_VAR_ASSIGN_STRLEN
	bcf STATUS, Z
	bcf STATUS, C
	movf VIC_VAR_ASSIGN_STRIDX, W
	subwf VIC_VAR_ASSIGN_STRLEN, W
	;; W == 0
	btfsc STATUS, Z
	goto _op_concat_bytev_end
	;; we have space, let's add byte
	banksel dvar
	movlw dvar
	movwf FSR
	banksel didx
	movf didx, W
	addwf FSR, F
	banksel bvar
	movf bvar, W
	movwf INDF
	banksel didx
	incf didx, F
_op_concat_bytev_end:
	nop ;; no space left
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

;;;;;;; ISR1_PARAM0 VARIABLES ;;;;;;
ISR1_PARAM0_UDATA udata
ISR1_PARAM0 res 1

m_usart_read_byte macro rvar
	local _usart_read_byte_0
	banksel VIC_VAR_USART_RIDX
	clrf VIC_VAR_USART_RIDX
	banksel PIR1
	btfss PIR1, RCIF
	goto $ - 1
	btfsc RCSTA, OERR
	bcf RCSTA, CREN
	btfsc RCSTA, FERR
	bcf RCSTA, CREN
_usart_read_byte_0:
	banksel RCREG
	movf RCREG, W
	banksel rvar
	movwf rvar
	banksel RCSTA
	btfss RCSTA, CREN
	bsf RCSTA, CREN
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


	goto _start
	nop
	nop
	nop

	org 4
ISR:
_isr_entry:
	movwf ISR_W
	movf STATUS, W
	movwf ISR_STATUS

_isr_rx_uart:
	banksel PIE1
	btfss PIE1, RCIF
	goto _end_isr_1
	btfsc RCSTA, OERR
	bcf RCSTA, CREN
	btfsc RCSTA, FERR
	bcf RCSTA, CREN
	banksel RCREG
	movf RCREG, W
	banksel ISR1_PARAM0
	movwf ISR1_PARAM0

	banksel RCSTA
	btfss RCSTA, CREN
	bsf RCSTA, CREN
	goto _isr_1
_end_isr_1:

	goto _isr_exit

;;;; generated code for ISR1
_isr_1:

	m_op_concat_bytev MYVAR2, VIC_STRSZ_MYVAR2, MYVAR2_IDX, ISR1_PARAM0

	goto _end_isr_1 ;; go back to end of block

;;;; end of _isr_1
_isr_exit:
	movf ISR_STATUS, W
	movwf STATUS
	swapf ISR_W, F
	swapf ISR_W, W
	retfie



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



	;;;; storing an empty string in MYVAR2
	m_op_nullify_str MYVAR2, VIC_STRSZ_MYVAR2, MYVAR2_IDX

;;;; UART read is done using isr_rx_uart;;; enable interrupt servicing for UART
	banksel INTCON
	bsf INTCON, GIE
	bsf INTCON, PEIE
	banksel PIE1
	bsf PIE1, RCIE
;;; end of interrupt servicing for UART

;;; sending the string 'Hello World!' to UART
;;;; byte array has length 0x0C
	m_usart_write_bytetbl _vic_str_01, 0x0C

_end_start:

	goto $	;;;; end of Main

;;;; generated code for functions
	;; not storing an empty string
	;;storing string 'Hello World!'
_vic_str_01:
	addwf PCL, F
	dt 0x48,0x65,0x6C,0x6C,0x6F,0x20,0x57,0x6F,0x72,0x6C,0x64,0x21,0x00

;;;; generated code for end-of-file
	end
...

compiles_ok($input, $output);
