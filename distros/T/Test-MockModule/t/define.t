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

# GH #64: define() then redefine() then unmock() should restore the defined sub
{
	my $m = Test::MockModule->new('Mockee64', no_auto => 1);
	$m->define( 'wrapper', sub { 'defined_value' } );
	is( Mockee64::wrapper(), 'defined_value', 'define() installs the sub' );

	$m->redefine( 'wrapper', sub { 'redefined_value' } );
	is( Mockee64::wrapper(), 'redefined_value', 'redefine() replaces the defined sub' );

	$m->unmock( 'wrapper' );
	is( Mockee64::wrapper(), 'defined_value', 'unmock() restores the originally defined sub (GH #64)' );
}

done_testing();

#----------------------------------------------------------------------

package Mockee; ## no critic (Modules::RequireFilenameMatchesPackage)

our $VERSION;
BEGIN { $VERSION = 1 }

sub existing_subroutine { 1 }

1;

package Mockee64; ## no critic (Modules::RequireFilenameMatchesPackage)

our $VERSION;
BEGIN { $VERSION = 1 }

1;
