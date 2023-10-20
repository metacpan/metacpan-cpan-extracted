package AltPort;
# Inheritance test for test3.t and test4.t only

our $VERSION = '0.20';
require Exporter;
use Win::SerialPort qw( :STAT :PARAM 0.20 );
our @ISA = qw( Exporter Win::SerialPort );
our @EXPORT= qw();
our @EXPORT_OK= @Win::SerialPort::EXPORT_OK;
our %EXPORT_TAGS = %Win::SerialPort::EXPORT_TAGS;

my $in = BM_fCtsHold;
print "AltPort import=$in\n";
1;
