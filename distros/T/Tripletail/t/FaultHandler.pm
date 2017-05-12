
package t::FaultHandler;
use strict;
use warnings;

1;

sub my_fault_handler
{
	my $pkg = shift;
	my $err = shift;
	print "Status: 500\r\n";
	print "Content-Type: text/plain\r\n";
	print "\r\n";
	print "pkg = $pkg\n";
	print "err = $err\n";
}

