use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule qw/strict/;

my $mocker = Test::MockModule->new('Mockee');

is( Test::MockModule->_strict_mode(), 1, "use Test::MockModule qw/strict/; sets strict mode" );

eval { $mocker->mock( 'foo', 2 ) };
like( "$@", qr/^mock is not allowed in strict mode. Please use define or redefine at/, "mock croaks in strict mode." );

eval { $mocker->noop('foo') };
like( "$@", qr/^noop is not allowed in strict mode. Please use define or redefine at/, "noop croaks in strict mode." );

$mocker->define( 'foo', "abc" );
is( Mockee->foo, "abc", "define is allowed in strict mode." );

$mocker->redefine( 'existing_subroutine', "def" );
is( Mockee->existing_subroutine, "def", "redefine is allowed in strict mode." );

{
    use Test::MockModule 'nostrict'; # no strictness in this lexical scope
    is( Test::MockModule->_strict_mode(), 0, "nostrict turns strictness off");
    $mocker->mock( 'foo', 123 );
    is( Mockee->foo, 123, "mock is allowed when strict mode is turned off." );
    {
        use Test::MockModule 'strict'; # but we are strict here again
        eval { $mocker->mock( 'foo', 2 ) };
        like( "$@", qr/^mock is not allowed in strict mode/,
            "we can nest alternating strict/nostrict soooo deeply");
    }
    $mocker->mock('foo', 456);
    pass("Back in a non-strict scope, the intervening strict scope didn't make ->mock() crash");
}

eval { $mocker->mock( 'foo', 2 ) };
like( "$@", qr/^mock is not allowed in strict mode. Please use define or redefine at/, "Finally, back in the original scope, and we return to being strict");

use Test::MockModule 'nostrict'; # same lexical scope as we opened in, but change how strict it is
$mocker->mock('foo', 94);
pass("Changed to nostrict in a previously strict scope, mock() didn't crash");

done_testing();

#----------------------------------------------------------------------

package Mockee;

our $VERSION;
BEGIN { $VERSION = 1 }

sub existing_subroutine { 1 }

1;
