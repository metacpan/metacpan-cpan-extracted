#!/usr/bin/env perl
#
# Fun rewriting modes
#
use strict;
use warnings;
use lib 'lib', '../lib';

use Wordsmith::Claude qw(rewrite);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $boring = "Please remember to submit your timesheets by Friday. Late submissions will not be processed until the following pay period.";

print "BORING OFFICE EMAIL:\n$boring\n\n";
print "=" x 60, "\n";

my @fun_modes = qw(pirate shakespeare yoda corporate valley noir uwu genz);

for my $mode (@fun_modes) {
    print "\n[$mode]:\n";
    my $result = rewrite(
        text => $boring,
        mode => $mode,
        loop => $loop,
    )->get;
    print $result->text, "\n";
}
