use utf8;

use v5.14;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw( dies );
use Test2::Tools::Warnings  qw( warning );

use Text::Minify::XS qw( minify_utf8 );

for my $n ( 10, 11, 100, 101, 1000, 1001 ) {

    like(
        dies {
            minify_utf8( chr(0xfe) x $n );
        },
        qr/Malformed UTF-8/,
        'got exception'
    );

}

done_testing;
