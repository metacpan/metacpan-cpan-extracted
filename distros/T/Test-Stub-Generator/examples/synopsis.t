use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use Test::Stub::Generator qw(make_method_utils);

###
# sample package
###
package Some::Class;
sub new { bless {}, shift };
sub method;

###
# test code
###
package main;

my $MEANINGLESS = -1;

my ($stub_method, $util) = make_method_utils(
#my $method = make_method(
    [
        # checking argument
        { expects => [ 0, 1 ], return => $MEANINGLESS },
        # control return_values
        { expects => [$MEANINGLESS], return => [ 0, 1 ] },

        # expects supported ignore(Test::Deep) and type(Test::Deep::Matcher)
        { expects => [ignore, 1],  return => $MEANINGLESS },
        { expects => [is_integer], return => $MEANINGLESS },
    ],
    { message => 'method arguments are ok' }
);

my $obj = Some::Class->new;
*Some::Class::method = $stub_method;
# ( or use Test::Mock::Guard )
# my $mock_guard = mock_guard( $obj => +{ method => $stub_method } );

# { expects => [ 0, 1 ], return => xxxx }
$obj->method( 0, 1 );
# ok xxxx- method arguments are ok

is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'return values are as You expected' );
# { expects => xxxx, return => [ 0, 1 ] }
# ok xxxx- return values are as You expected

$obj->method( sub{}, 1 );
# { expects => [ignore, 1], return => xxxx }
# ok xxxx- method arguments are ok

$obj->method(1);
# { expects => [is_integer], return => xxxx }
# ok xxxx- method arguments are ok

ok( !$util->has_next, 'empty' );
is( $util->called_count, 4, 'called_count is 4' );

done_testing;

