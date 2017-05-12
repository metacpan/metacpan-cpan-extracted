use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Difference;

my $diff = undef;

lives_ok {
    $diff = Text::Difference->new(
        a => "NEW-OEM Gopro-Ass.HTL-202 Bicycle Handlebar/Seatpost Clamp with Three-way Adjustable Pivot for GoPro",
        b => "NEW-OEM Gopro-Ass.HTL-202 Bicycle Handlebar/Seatpost Clamp with Three-way Adjustable Pivot for GoPro",
        stopwords => ['/',
    '(',
    ')',
    '&',
    '-',
    ',',
    ' - '],
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );




done_testing();
