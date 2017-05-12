#!/pro/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use_ok "Text::OutputFilter";

my $lm = 4;
@ARGV and $ARGV[0] =~ m/^\d+$/ && ! -f $ARGV[0] and $lm = 0 + shift;

my $buf = "";
my $expect;

local $, = "+";
ok (1, "Now with \$, set to '$,'");
$buf = "";
tie *STDOUT, "Text::OutputFilter", $lm, \$buf;

$expect  = "    I\n";
print "I\n";
is ($buf, $expect, "single arg with newline, line 1");

$expect .= "    am\n";
print "am\n";
is ($buf, $expect, "single arg with newline, line 2");

$expect .= "    I+am+\n";
print "I", "am", "\n";
is ($buf, $expect, "three args with newline");

print "I";
is ($buf, $expect, "one arg, no newline");
print "am", "me";
is ($buf, $expect, "two args, no newline");

$expect .= "    Iam+me";
close STDOUT;
is ($buf, $expect, "closed");

untie *STDOUT;
