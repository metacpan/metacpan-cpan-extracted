package AltPort;
# Inheritance test for test3.t and test4.t only

our $VERSION = '0.20';
require Exporter;
use Win32::SerialPort qw( :STAT :PARAM 0.20 );
our @ISA = qw( Exporter Win32::SerialPort );
our @EXPORT= qw();
our @EXPORT_OK= @Win32::SerialPort::EXPORT_OK;
our %EXPORT_TAGS = %Win32::SerialPort::EXPORT_TAGS;

my $in = BM_fCtsHold;
print "AltPort import=$in\n";
1;
