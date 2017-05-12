use strict;
use warnings;

use Test::Some '~', '!skip_me';

use Test::More tests => 1;

sub _passing { plan tests => 1; pass }
sub _failing { plan tests => 1; fail }

subtest 'test_me'     => \&_passing;
subtest 'skip_me'     => \&_failing;
