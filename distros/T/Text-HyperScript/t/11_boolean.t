use strict;
use warnings;

use Test2::V0;
use Text::HyperScript qw( true false );

sub main {
    my $true = true;

    ok( $true->is_true );
    ok( !$true->is_false );
    ok( !!$true );

    my $false = false;

    ok( !$false->is_true );
    ok( $false->is_false );
    ok( !$false );

    done_testing;
}

main;
