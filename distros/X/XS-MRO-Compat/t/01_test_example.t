#!perl -w

use strict;
use Test::More;
use Config;

my $make = $Config{make};

chdir 'example' or die "chdir 'example' failed: $!";

sub cmd{
	my $cmd = join ' ', @_;
	`$cmd` or die "Cannot call system command `$cmd`: $?";
	is $?, 0, $cmd;
}

cmd $^X, '-Mblib', 'Makefile.PL';
#cmd $make;

#cmd $make, 'test';

cmd $make, 'clean';

done_testing;
