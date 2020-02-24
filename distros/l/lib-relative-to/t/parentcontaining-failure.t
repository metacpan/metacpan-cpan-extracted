use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib::relative::to;

throws_ok {
    lib::relative::to->import(ParentContaining => '!/@/#/\\/', 'hlagh')
} qr/in any parent directory.*parentcontaining-failure.t/, "caught failure" ||
note($@);

done_testing();
