use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule;

my $mocker = Test::MockModule->new('Mockee');

$mocker->define( 'doesnt_exist', 2 );
is( Mockee::doesnt_exist(), 2, 'define() allows us to mock nonexistant subroutines.' );

eval { $mocker->define( 'existing_subroutine', 6 ) };
like( $@, qr/Mockee::existing_subroutine exists\!/, 'exception when define()ing an existing subroutine' );

undef $mocker;
is( Mockee->can('doesnt_exist'), undef, "the defined sub went away after mocker is undeffed" );
$mocker = Test::MockModule->new('Mockee');

$mocker->define( 'doesnt_exist', 3 );
is( Mockee::doesnt_exist(), 3, 'The subroutine can be defined again after the mock object goes out of scope and is re-instantiated.' );

done_testing();

#----------------------------------------------------------------------

package Mockee;

our $VERSION;
BEGIN { $VERSION = 1 }

sub existing_subroutine { 1 }

1;
