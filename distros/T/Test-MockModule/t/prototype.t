use warnings;
use strict;

use Test::More;
use Test::Warnings;

package Mockee;

sub good ($$);

sub good ($$) {
    my ( $bar, $baz ) = @_;
    return ( $bar + 1, $baz + 2 );
}

1;

package main;

use Test::MockModule;

$INC{'Mockee.pm'} = 1;
my $mocker = Test::MockModule->new('Mockee');

$mocker->redefine( 'good', 2 );

done_testing();

#----------------------------------------------------------------------

