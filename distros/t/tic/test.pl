#!/usr/bin/perl

use strict;
use IO::Select;
use IO::Stty;
use Term::ReadKey;


my $s = new IO::Select->new();
$s->add(\*STDIN);
my $char;

ReadMode 3;

while (1) {
	$char = ReadKey(-1);
	if (defined($char)) {
		print "--> $char\n";
	}

}
