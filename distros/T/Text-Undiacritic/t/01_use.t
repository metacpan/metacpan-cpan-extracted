use strict;
use warnings;
use Test::More;

use File::Basename;

BEGIN {
    require lib;
    lib->import( grep { -d $_; } map { dirname(__FILE__) . "/$_"; }
        qw(lib ../lib ../blib/lib)
    );
}

plan tests => 1;

use_ok('Text::Undiacritic');


