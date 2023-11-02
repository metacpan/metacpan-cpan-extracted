use v5.14;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw( lives );
use Test2::Tools::Warnings qw( warning );

use Text::Minify::XS qw( minify minify_ascii );

ok lives {

    is minify(undef), undef;

    is minify_ascii(undef), undef;

};

done_testing;
