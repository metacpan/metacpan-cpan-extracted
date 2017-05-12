#!perl

use strict;
use warnings;
use Test::Simple tests => 1;

my ( $t );

foreach my $m ( qw( kernel ) ) {
    ok( $t->{'pfact'}->{$m} = _pfact( $m ), "$m: $t->{'pfact'}->{$m}" );
}

sub _pfact {
    my $m = shift;

    eval "use Pfacter::$m";
    return "Pfacter::$m"->pfact( $t );
}
