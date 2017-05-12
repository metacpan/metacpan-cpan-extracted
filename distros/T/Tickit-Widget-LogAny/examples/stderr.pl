#!/usr/bin/env perl
use strict;
use warnings;

use Tickit;
use Tickit::Widget::LogAny;

my $tickit = Tickit->new(
	root => Tickit::Widget::LogAny->new(
		stderr => 1,
	)
);
print STDERR "print to STDERR\n";
printf STDERR "printf(...) to %s", 'STDERR';
$tickit->run;
