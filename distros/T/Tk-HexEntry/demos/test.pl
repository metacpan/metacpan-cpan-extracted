#!perl
use strict;

use lib '../.';

use Tk;
use Tk::HexEntry;


my $mw = MainWindow->new;

my $var;

my $en = $mw->HexEntry(
	-textvariable => \$var,
	-minvalue => 0,
	-maxvalue => 0xff,
	-increment=> 0x05,
	)->pack;

$en->value('0xaf');

# or ..

$en->value(sprintf('%x', 10));

#$mw->repeat(1000, [\&incvar, \$var]);

MainLoop();

sub incvar {
	my $var = shift;
	$$var = sprintf('%x', hex($$var) + 1);
	print $$var, "\n";
}

__END__