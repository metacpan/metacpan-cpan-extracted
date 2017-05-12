#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese);

# Very basic. Just check matching speed for now - not realy a sensible
# test of much at all in fact.

my $code   = <<'EOC';
    my $x  = join( '', 'A' .. 'Z' ) x 1000;
    my $mz = join '', 'M' .. 'Z';
    for ( 1 .. 100 ) {
        $x =~ s/[M-Z]+/:/g;
        $x =~ s/:/$mz/g;
    }
EOC

my %engine = (
    Perl      => "",
    Oniguruma => "use re::engine::Oniguruma;\n"
);

my %tests = map { $_ => $engine{$_} . $code } keys %engine;

cmpthese( 0, \%tests );
