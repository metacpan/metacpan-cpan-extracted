use strict;
use warnings;

use Test::Some qr/test_me/, '/too';

use Test::More tests => 3;

sub _passing { plan tests => 1; pass }
sub _failing { plan tests => 1; fail }

subtest 'test_me'     => \&_passing;
subtest 'test_me_too' => \&_passing;
subtest 'skip_me'     => \&_failing;
