use strict;
use warnings;

use Test::More;
use Test::Requires::Env (
    +{
        HOME => $ENV{HOME},
        PATH => qr{/path/to/unknown},
    },
);

fail 'Do not reach here';

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
