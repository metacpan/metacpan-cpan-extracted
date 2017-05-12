use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 166;
}
cmp_ok($Win32::SerialPort::VERSION, '>=', 0.20, 'VERSION check');

use Win32::SerialPort qw( :STAT 0.20 );

use strict;
use warnings;

use Win32API::CommPort qw( :RAW :COMMPROP :DCB 0.12 );	# check misc. exports
use Win32;

my $tc = 2;		# next test number
my $null=0;
my $event=0;
my $ok=0;

## 2 - 26 CommPort Win32::API objects

ok(defined &CloseHandle, 'defined &CloseHandle');
ok(defined &CreateFile, 'defined &CreateFile');
ok(defined &GetCommState, 'defined &GetCommState');
ok(defined &ReadFile, 'defined &ReadFile');
ok(defined &SetCommState, 'defined &SetCommState');
ok(defined &SetupComm, 'defined &SetupComm');
ok(defined &PurgeComm, 'defined &PurgeComm');
ok(defined &CreateEvent, 'defined &CreateEvent');
ok(defined &GetCommTimeouts, 'defined &GetCommTimeouts');
ok(defined &SetCommTimeouts, 'defined &SetCommTimeouts');
ok(defined &GetCommProperties, 'defined &GetCommProperties');
ok(defined &ClearCommBreak, 'defined &ClearCommBreak');
ok(defined &ClearCommError, 'defined &ClearCommError');
ok(defined &EscapeCommFunction, 'defined &EscapeCommFunction');
ok(defined &GetCommConfig, 'defined &GetCommConfig');
ok(defined &GetCommMask, 'defined &GetCommMask');
ok(defined &GetCommModemStatus, 'defined &GetCommModemStatus');
ok(defined &SetCommBreak, 'defined &SetCommBreak');
ok(defined &SetCommConfig, 'defined &SetCommConfig');
ok(defined &SetCommMask, 'defined &SetCommMask');
ok(defined &TransmitCommChar, 'defined &TransmitCommChar');

ok(defined &WaitCommEvent, 'defined &WaitCommEvent');
ok(defined &WriteFile, 'defined &WriteFile');
ok(defined &ResetEvent, 'defined &ResetEvent');
ok(defined &GetOverlappedResult, 'defined &GetOverlappedResult');

is(PURGE_TXABORT, 0x1, 'PURGE_TXABORT');
is(PURGE_RXABORT, 0x2, 'PURGE_RXABORT');
is(PURGE_TXCLEAR, 0x4, 'PURGE_TXCLEAR');
is(PURGE_RXCLEAR, 0x8, 'PURGE_RXCLEAR');

is(SETXOFF, 0x1, 'SETXOFF');
is(SETXON, 0x2, 'SETXON');
is(SETRTS, 0x3, 'SETRTS');
is(CLRRTS, 0x4, 'CLRRTS');
is(SETDTR, 0x5, 'SETDTR');
is(CLRDTR, 0x6, 'CLRDTR');
is(SETBREAK, 0x8, 'SETBREAK');
is(CLRBREAK, 0x9, 'CLRBREAK');

is(EV_RXCHAR, 0x1, 'EV_RXCHAR');
is(EV_RXFLAG, 0x2, 'EV_RXFLAG');
is(EV_TXEMPTY, 0x4, 'EV_TXEMPTY');
is(EV_CTS, 0x8, 'EV_CTS');
is(EV_DSR, 0x10, 'EV_DSR');
is(EV_RLSD, 0x20, 'EV_RLSD');

is(EV_BREAK, 0x40, 'EV_BREAK');
is(EV_ERR, 0x80, 'EV_ERR');
is(EV_RING, 0x100, 'EV_RING');
is(EV_PERR, 0x200, 'EV_PERR');
is(EV_RX80FULL, 0x400, 'EV_RX80FULL');
is(EV_EVENT1, 0x800, 'EV_EVENT1');
is(EV_EVENT2, 0x1000, 'EV_EVENT2');

is(ERROR_IO_INCOMPLETE, 996, 'ERROR_IO_INCOMPLETE');
is(ERROR_IO_PENDING, 997, 'ERROR_IO_PENDING');

is(BAUD_075, 0x1, 'BAUD_075');
is(BAUD_110, 0x2, 'BAUD_110');
is(BAUD_134_5, 0x4, 'BAUD_134_5');
is(BAUD_150, 0x8, 'BAUD_150');
is(BAUD_300, 0x10, 'BAUD_300');
is(BAUD_600, 0x20, 'BAUD_600');
is(BAUD_1200, 0x40, 'BAUD_1200');
is(BAUD_1800, 0x80, 'BAUD_1800');
is(BAUD_2400, 0x100, 'BAUD_2400');
is(BAUD_4800, 0x200, 'BAUD_4800');
is(BAUD_7200, 0x400, 'BAUD_7200');
is(BAUD_9600, 0x800, 'BAUD_9600');
is(BAUD_14400, 0x1000, 'BAUD_14400');

is(BAUD_19200, 0x2000, 'BAUD_19200');
is(BAUD_38400, 0x4000, 'BAUD_38400');
is(BAUD_56K, 0x8000, 'BAUD_56K');
is(BAUD_57600, 0x40000, 'BAUD_57600');
is(BAUD_115200, 0x20000, 'BAUD_115200');
is(BAUD_128K, 0x10000, 'BAUD_128K');
is(BAUD_USER, 0x10000000, 'BAUD_USER');

is(PST_FAX, 0x21, 'PST_FAX');
is(PST_LAT, 0x101, 'PST_LAT');
is(PST_MODEM, 0x6, 'PST_MODEM');
is(PST_NETWORK_BRIDGE, 0x100, 'PST_NETWORK_BRIDGE');
is(PST_PARALLELPORT, 0x2, 'PST_PARALLELPORT');
is(PST_RS232, 0x1, 'PST_RS232');
is(PST_RS422, 0x3, 'PST_RS422');
is(PST_RS423, 0x4, 'PST_RS423');
is(PST_RS449, 0x5, 'PST_RS449');
is(PST_SCANNER, 0x22, 'PST_SCANNER');
is(PST_TCPIP_TELNET, 0x102, 'PST_TCPIP_TELNET');
is(PST_UNSPECIFIED, 0x0, 'PST_UNSPECIFIED');
is(PST_X25, 0x103, 'PST_X25');
is(PCF_16BITMODE, 0x200, 'PCF_16BITMODE');
is(PCF_DTRDSR, 0x1, 'PCF_DTRDSR');

is(PCF_INTTIMEOUTS, 0x80, 'PCF_INTTIMEOUTS');
is(PCF_PARITY_CHECK, 0x8, 'PCF_PARITY_CHECK');
is(PCF_RLSD, 0x4, 'PCF_RLSD');
is(PCF_RTSCTS, 0x2, 'PCF_RTSCTS');
is(PCF_SETXCHAR, 0x20, 'PCF_SETXCHAR');
is(PCF_SPECIALCHARS, 0x100, 'PCF_SPECIALCHARS');
is(PCF_TOTALTIMEOUTS, 0x40, 'PCF_TOTALTIMEOUTS');
is(PCF_XONXOFF, 0x10, 'PCF_XONXOFF');

is(SP_SERIALCOMM, 0x1, 'SP_SERIALCOMM');
is(SP_BAUD, 0x2, 'SP_BAUD');
is(SP_DATABITS, 0x4, 'SP_DATABITS');
is(SP_HANDSHAKING, 0x10, 'SP_HANDSHAKING');
is(SP_PARITY, 0x1, 'SP_PARITY');
is(SP_PARITY_CHECK, 0x20, 'SP_PARITY_CHECK');
is(SP_RLSD, 0x40, 'SP_RLSD');
is(SP_STOPBITS, 0x8, 'SP_STOPBITS');

is(DATABITS_5, 0x1, 'DATABITS_5');
is(DATABITS_6, 0x2, 'DATABITS_6');
is(DATABITS_7, 0x4, 'DATABITS_7');
is(DATABITS_8, 0x8, 'DATABITS_8');
is(DATABITS_16, 0x10, 'DATABITS_16');
is(DATABITS_16X, 0x20, 'DATABITS_16X');

is(STOPBITS_10, 0x1, 'STOPBITS_10');
is(STOPBITS_15, 0x2, 'STOPBITS_15');
is(STOPBITS_20, 0x4, 'STOPBITS_20');

is(PARITY_NONE, 0x100, 'PARITY_NONE');
is(PARITY_ODD, 0x200, 'PARITY_ODD');
is(PARITY_EVEN, 0x400, 'PARITY_EVEN');
is(PARITY_MARK, 0x800, 'PARITY_MARK');
is(PARITY_SPACE, 0x1000, 'PARITY_SPACE');

is(COMMPROP_INITIALIZED, 0xe73cf52e, 'COMMPROP_INITIALIZED');

is(CBR_110, 110, 'CBR_110');
is(CBR_300, 300, 'CBR_300');
is(CBR_600, 600, 'CBR_600');
is(CBR_1200, 1200, 'CBR_1200');
is(CBR_2400, 2400, 'CBR_2400');
is(CBR_4800, 4800, 'CBR_4800');
is(CBR_9600, 9600, 'CBR_9600');
is(CBR_14400, 14400, 'CBR_14400');
is(CBR_19200, 19200, 'CBR_19200');
is(CBR_38400, 38400, 'CBR_38400');
is(CBR_56000, 56000, 'CBR_56000');
is(CBR_57600, 57600, 'CBR_57600');
is(CBR_115200, 115200, 'CBR_115200');

is(CBR_128000, 128000, 'CBR_128000');
is(CBR_256000, 256000, 'CBR_256000');

is(DTR_CONTROL_DISABLE, 0x0, 'DTR_CONTROL_DISABLE');
is(DTR_CONTROL_ENABLE, 0x1, 'DTR_CONTROL_ENABLE');
is(DTR_CONTROL_HANDSHAKE, 0x2, 'DTR_CONTROL_HANDSHAKE');
is(RTS_CONTROL_DISABLE, 0x0, 'RTS_CONTROL_DISABLE');
is(RTS_CONTROL_ENABLE, 0x1, 'RTS_CONTROL_ENABLE');
is(RTS_CONTROL_HANDSHAKE, 0x2, 'RTS_CONTROL_HANDSHAKE');
is(RTS_CONTROL_TOGGLE, 0x3, 'RTS_CONTROL_TOGGLE');

is(EVENPARITY, 0x2, 'EVENPARITY');
is(MARKPARITY, 0x3, 'MARKPARITY');
is(NOPARITY, 0x0, 'NOPARITY');
is(ODDPARITY, 0x1, 'ODDPARITY');
is(SPACEPARITY, 0x4, 'SPACEPARITY');

is(ONESTOPBIT, 0x0, 'ONESTOPBIT');
is(ONE5STOPBITS, 0x1, 'ONE5STOPBITS');
is(TWOSTOPBITS, 0x2, 'TWOSTOPBITS');

is(FM_fBinary, 0x1, 'FM_fBinary');
is(FM_fParity, 0x2, 'FM_fParity');
is(FM_fOutxCtsFlow, 0x4, 'FM_fOutxCtsFlow');
is(FM_fOutxDsrFlow, 0x8, 'FM_fOutxDsrFlow');
is(FM_fDtrControl, 0x30, 'FM_fDtrControl');
is(FM_fDsrSensitivity, 0x40, 'FM_fDsrSensitivity');
is(FM_fTXContinueOnXoff, 0x80, 'FM_fTXContinueOnXoff');

is(FM_fOutX, 0x100, 'FM_fOutX');
is(FM_fInX, 0x200, 'FM_fInX');
is(FM_fErrorChar, 0x400, 'FM_fErrorChar');
is(FM_fNull, 0x800, 'FM_fNull');
is(FM_fRtsControl, 0x3000, 'FM_fRtsControl');
is(FM_fAbortOnError, 0x4000, 'FM_fAbortOnError');
is(FM_fDummy2, 0xffff8000, 'FM_fDummy2');

$event = CreateEvent($null,	# no security
		     1,		# explicit reset req
		     0,		# initial event reset
		     $null);	# no name

ok($event, 'CreateEvent');
Win32API::CommPort->OS_Error unless ($event);

ResetEvent($event);
$ok = Win32::GetLastError;
is($ok, 0, 'Win32::GetLastError PASS');
print "Should Pass: ";
Win32API::CommPort->OS_Error;

$ok = CloseHandle($event);	# $MS doesn't check return either

ResetEvent($event);
$ok = Win32::GetLastError;
ok($ok > 0, 'Win32::GetLastError FAIL');
print "Should Fail: ";
Win32API::CommPort->OS_Error;

