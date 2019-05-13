use strict;
use warnings;

use Test::More;

use_ok('Text::Control');

my $test_string = "\x00\\Hi\x7fthere.\x80\xff";

is( Text::Control::to_dot($test_string), ".\\Hi.there...", 'to_dot()' );

is(
    Text::Control::to_hex($test_string),
    '\x00\\\\Hi\x7fthere.\x80\xff',
    'to_hex()',
);

is(
    Text::Control::from_hex( Text::Control::to_hex($test_string) ),
    $test_string,
    'round-trip: to_hex() -> from_hex()',
);

for my $ord ( 0 .. 0x1f, 0x7f .. 0xff ) {
    like( Text::Control::to_hex(chr $ord), qr<\A\\x>, "ASCII byte $ord is escaped" );
}

done_testing();
