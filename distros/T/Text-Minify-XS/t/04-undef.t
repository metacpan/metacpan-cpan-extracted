use Test::More 1.302183;
use Test::Exception 0.41;
use Test::Warnings qw/ warning /;

use_ok "Text::Minify::XS", qw( minify minify_ascii );

lives_ok {

    is minify(undef), undef;

    is minify_ascii(undef), undef;

};

done_testing;
