# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

######################### We start with some black magic to print on failure.

use strict;
use warnings;
use Test::More tests => 4;

# Just make sure everything compiles
use_ok("cpan2rpm");
use_ok("CPAN::RPM");

my $exefile = "cpan2rpm";
my $try = `$^X -c -Ilib $exefile 2>&1 | head`;
ok(!$?, "compile $exefile: clean exit");
chomp $try;
ok (($try =~ /(syntax OK)/i), "compile $exefile: $try");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
