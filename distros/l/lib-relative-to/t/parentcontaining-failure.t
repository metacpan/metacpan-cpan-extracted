use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib::relative::to;

use Directory::relative::to qw(relative_dir);

throws_ok {
    lib::relative::to->import(ParentContaining => '!/@/#/\\/', 'hlagh')
} qr/in any parent directory.*parentcontaining-failure.t/, "caught failure" ||
note($@);

throws_ok {
    relative_dir(ParentContaining => '!/@/#/\\/', 'hlagh')
} qr/in any parent directory.*parentcontaining-failure.t/, "caught failure in Directory::relative::to" ||
note($@);

done_testing();
