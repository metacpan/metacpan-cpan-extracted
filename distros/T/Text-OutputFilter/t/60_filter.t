#!/pro/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use_ok "Text::OutputFilter";

my $lm = 4;
@ARGV and $ARGV[0] =~ m/^\d+$/ && ! -f $ARGV[0] and $lm = 0 + shift;

my $buf = "";
my $expect;

# Test *Filter* funtionality
tie *STDOUT, "Text::OutputFilter", 1, \$buf,
    sub { $_[0] =~ m/\blike\b/ ? undef : ":$_[0]\$" };

$expect  = " :I\$\n :do\$\n :filtering\$\n";
print "I\ndo\nlike\nfiltering\n";
is ($buf, $expect, "single arg with newline, line 1");

untie *STDOUT;
