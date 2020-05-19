#! perl -w
use strict;
use Test::More;
use Test::NoWarnings ();
use Test::Fatal qw( lives_ok );

use Test::Smoke::Util::Serialise;

Test::Smoke::Util::Serialise->import( 'serialise' );

my $string;
lives_ok(
    sub { $string = serialise(\1); }, 
    "'serialise()' was imported"
);
is($string, "\\1", "serialise() worked");

my $four = qr{^ four $}x;
my $origin = {one => 'two', three => $four, five => ['six', 'seven']};
is(
    serialise($origin),
    "{(five => [six, seven]), (one => two), (three => $four)}", # sort keys
    "basic serialise()"
) or diag(explain($origin));

my $object1 = bless {}, 'CannotSerialise';
like(
    serialise($object1),
    qr{ CannotSerialise = HASH \(0x [0-9a-f]+ \) $}x,
    "serialise() object1"
);

my $object2 = bless {}, 'CanSerialise';
is(
    serialise($object2),
    "I am a serial: 42",
    "serialise() object2"
);

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

package CanSerialise;
use overload
    '""' => sub { 'I am a serial: 42' },
    fallback => 1,
;
1;
