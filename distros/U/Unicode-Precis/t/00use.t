#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;

use Test::More;

BEGIN {
    if ($] < 5.008007) {
        plan skip_all => 'Perl prior to 5.8.7 are not supported';
    } else {
        plan tests => 4;
        use_ok('Unicode::Precis');
        use_ok('Unicode::Precis::OpaqueString');
        use_ok('Unicode::Precis::UsernameCaseMapped');
        use_ok('Unicode::Precis::UsernameCasePreserved');
    }
}
