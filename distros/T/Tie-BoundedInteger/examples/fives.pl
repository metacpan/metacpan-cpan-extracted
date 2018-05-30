#!/usr/bin/perl

use Tie::BoundedInteger;

tie my $number, 'Tie::BoundedInteger', 1, 3;

foreach my $try ( -5 .. 5 ) {
	my $value =  eval { $number = $try };

	print "Tried to assign [$try], ";
	print "but it didn't work, " unless $number == $try;
	print "value is now [$number]\n";
	}
