#!/usr/bin/env perl

# Regression test for https://github.com/cpan-authors/YAML-Syck/issues/32
# Magical variables like $. and $$ were incorrectly dumped as undef (~).

use warnings;
use strict;

use Test::More tests => 4;

use YAML::Syck;

# Test $. (current line number) - the original bug report
# Skipped on perl < 5.18 where mg_get for $. is a core perl issue
SKIP: {
    skip '$. magic not reliable before perl 5.18', 2 if $] < 5.018;

    open my $fh, "<", $0 or die "Cannot open $0: $!";
    <$fh> for 1..3;

    my $yaml = YAML::Syck::Dump({ dot => $. });
    close $fh;
    unlike( $yaml, qr/~/, '$. does not dump as undef' );
    like( $yaml, qr/dot: 3/, '$. dumps its numeric value' );
}

# Test $$ (process ID)
# Skipped on perl < 5.18 where mg_get for $$ is a core perl issue
SKIP: {
    skip '$$ magic not reliable before perl 5.18', 2 if $] < 5.018;

    my $yaml = YAML::Syck::Dump({ pid => $$ });
    unlike( $yaml, qr/~/, '$$ does not dump as undef' );
    like( $yaml, qr/pid: $$/, '$$ dumps its numeric value' );
}
