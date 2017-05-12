#!perl -T
use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use Test::MockPackages::Returns qw(returns_code);

my $coderef = returns_code {
    my ( @args ) = @ARG;

    return join ', ', @args;
};

isa_ok( $coderef, 'Test::MockPackages::Returns' );
is( $coderef->( 5, 6, 7 ), '5, 6, 7', 'original coderef still intact' );

done_testing();
