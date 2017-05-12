#!/usr/bin/perl
use strict;
use warnings;
use lib "lib";
use Test::More qw/no_plan/;

BEGIN {
    use_ok "Zen::Koans", 'dump_fortunes';
}

is dump_fortunes(), cat("t/fortune.txt");


sub cat {
    # lexical $fh will be closed automatically
    open(my $fh, $_[0]) or die "Can't open $_[0]: $!";
    local $/ = undef;
    return <$fh>;
}
