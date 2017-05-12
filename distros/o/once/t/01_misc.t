#!/usr/bin/env perl
use warnings;
use strict;
use once;
use Test::More tests => 1;
use Test::Differences;
my $output = '';
sub record { $output .= join '' => @_ }

sub doit {
    my ($level, $iterations) = @_;
    return if $level > 2;
    record "level $level: begin\n";
    for (1 .. $iterations) {
        record "level $level, block 1, iter $_: before\n";
        ONCE { record "level $level, block 1, iter $_: ONCE A\n" };
        record "level $level, block 1, iter $_: middle\n";
        ONCE { record "level $level, block 1, iter $_: ONCE B\n" };
        record "level $level, block 1, iter $_: after\n";
    }
    record "\n";
    doit($level + 1, $iterations);
    for (1 .. $iterations) {
        record "level $level, block 2, iter $_: before\n";
        ONCE { record "level $level, block 2, iter $_: ONCE A\n" };
        record "level $level, block 2, iter $_: middle\n";
        ONCE { record "level $level, block 2, iter $_: ONCE B\n" };
        record "level $level, block 2, iter $_: after\n";
    }
    record "level $level: end\n\n";
}
doit(1, 3);
doit(1, 3);
chomp $output;
eq_or_diff $output, <<EOEXPECT, 'output';
level 1: begin
level 1, block 1, iter 1: before
level 1, block 1, iter 1: ONCE A
level 1, block 1, iter 1: middle
level 1, block 1, iter 1: ONCE B
level 1, block 1, iter 1: after
level 1, block 1, iter 2: before
level 1, block 1, iter 2: middle
level 1, block 1, iter 2: after
level 1, block 1, iter 3: before
level 1, block 1, iter 3: middle
level 1, block 1, iter 3: after

level 2: begin
level 2, block 1, iter 1: before
level 2, block 1, iter 1: middle
level 2, block 1, iter 1: after
level 2, block 1, iter 2: before
level 2, block 1, iter 2: middle
level 2, block 1, iter 2: after
level 2, block 1, iter 3: before
level 2, block 1, iter 3: middle
level 2, block 1, iter 3: after

level 2, block 2, iter 1: before
level 2, block 2, iter 1: ONCE A
level 2, block 2, iter 1: middle
level 2, block 2, iter 1: ONCE B
level 2, block 2, iter 1: after
level 2, block 2, iter 2: before
level 2, block 2, iter 2: middle
level 2, block 2, iter 2: after
level 2, block 2, iter 3: before
level 2, block 2, iter 3: middle
level 2, block 2, iter 3: after
level 2: end

level 1, block 2, iter 1: before
level 1, block 2, iter 1: middle
level 1, block 2, iter 1: after
level 1, block 2, iter 2: before
level 1, block 2, iter 2: middle
level 1, block 2, iter 2: after
level 1, block 2, iter 3: before
level 1, block 2, iter 3: middle
level 1, block 2, iter 3: after
level 1: end

level 1: begin
level 1, block 1, iter 1: before
level 1, block 1, iter 1: middle
level 1, block 1, iter 1: after
level 1, block 1, iter 2: before
level 1, block 1, iter 2: middle
level 1, block 1, iter 2: after
level 1, block 1, iter 3: before
level 1, block 1, iter 3: middle
level 1, block 1, iter 3: after

level 2: begin
level 2, block 1, iter 1: before
level 2, block 1, iter 1: middle
level 2, block 1, iter 1: after
level 2, block 1, iter 2: before
level 2, block 1, iter 2: middle
level 2, block 1, iter 2: after
level 2, block 1, iter 3: before
level 2, block 1, iter 3: middle
level 2, block 1, iter 3: after

level 2, block 2, iter 1: before
level 2, block 2, iter 1: middle
level 2, block 2, iter 1: after
level 2, block 2, iter 2: before
level 2, block 2, iter 2: middle
level 2, block 2, iter 2: after
level 2, block 2, iter 3: before
level 2, block 2, iter 3: middle
level 2, block 2, iter 3: after
level 2: end

level 1, block 2, iter 1: before
level 1, block 2, iter 1: middle
level 1, block 2, iter 1: after
level 1, block 2, iter 2: before
level 1, block 2, iter 2: middle
level 1, block 2, iter 2: after
level 1, block 2, iter 3: before
level 1, block 2, iter 3: middle
level 1, block 2, iter 3: after
level 1: end
EOEXPECT
