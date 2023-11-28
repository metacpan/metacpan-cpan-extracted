#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( is like ) ], tests => 5;
use Test::Fatal qw( exception );

## no critic (RequireCarping)

my $expected_value = "Hello\n";
is exception {
  timeout 3 => sub { die( $expected_value ); };
},
  $expected_value,
  'no timeout: code dies (exception is a string with trailing newline)';

like exception {
  timeout 3 => sub { die( 'Hello' ) };
}, qr/\A Hello\ at\  /x, 'no timeout: code dies (exception is a string without trailing newline)';

$expected_value = 42;
is exception {
  timeout 3 => sub { die( [ $expected_value ] ) };
}
->[ 0 ], $expected_value, 'no timeout: code dies (exception is a plain array reference)';

my $foo = bless {}, 'Foo::Exception';
is exception {
  timeout 3 => sub { die $foo };
}, $foo, 'no timeout: code dies (exception is an object)';

$foo = sub { $expected_value };
is exception {
  timeout 3 => sub { die $foo };
}
->(), $expected_value, 'no timeout: code dies (exception is a plain code reference)';
