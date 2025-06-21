#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::Dir qw(dir);

my $TESDIR = File::Spec->catfile(qw/t data dir/);

is_deeply(
	[ dir($TESDIR) ],
	[ map { File::Spec->catfile($TESDIR, $_) } qw(a.txt b.txt c.txt) ],
	'dir ok'
);

is_deeply(
	[ dir($TESDIR, hidden => 1) ],
	[ map { File::Spec->catfile($TESDIR, $_) } qw(.hidden.txt a.txt b.txt c.txt) ],
	'dir(hidden => 1) ok'
);

done_testing;

# vim: expandtab shiftwidth=4
