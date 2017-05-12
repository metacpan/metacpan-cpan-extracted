#!/usr/bin/perl -w

use strict;


BEGIN	{ $| = 1; print "1..1\n"; }
END	{ print "not ok 1\n" unless $::tiestderrloaded; }


BEGIN { print "Load the module: use Tie::STDERR\n"; }

use Tie::STDERR '| cat -';
$::tiestderrloaded = 1;
print "ok 1\n";

use Tie::STDERR undef;

### print STDERR "Test output\n";

