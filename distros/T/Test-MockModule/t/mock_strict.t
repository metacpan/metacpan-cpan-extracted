use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule qw/strict/;

my $mocker = Test::MockModule->new('Mockee');

is( $Test::MockModule::STRICT_MODE, 1, "use Test::MockModule qw/strict/; sets \$STRICT_MODE to 1" );

eval { $mocker->mock( 'foo', 2 ) };
like( "$@", qr/^mock is not allowed in strict mode. Please use define or redefine at/, "mock croaks in strict mode." );

eval { $mocker->noop('foo') };
like( "$@", qr/^noop is not allowed in strict mode. Please use define or redefine at/, "noop croaks in strict mode." );

$mocker->define( 'foo', "abc" );
is( Mockee->foo, "abc", "define is allowed in strict mode." );

$mocker->redefine( 'existing_subroutine', "def" );
is( Mockee->existing_subroutine, "def", "redefine is allowed in strict mode." );

$Test::MockModule::STRICT_MODE = 0;
$mocker->mock( 'foo', 123 );
is( Mockee->foo, 123, "mock is allowed when strict mode is turned off." );

done_testing();

#----------------------------------------------------------------------

package Mockee;

our $VERSION;
BEGIN { $VERSION = 1 }

sub existing_subroutine { 1 }

1;
