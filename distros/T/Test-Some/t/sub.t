use strict;
use warnings;

use 5.10.0;

use Test::Some '~', sub { state $i; $i++ < 2; };

use Test::More tests => 2;

sub _passing { plan tests => 1; pass }
sub _failing { plan tests => 1; fail }

subtest 'test_me'     => \&_passing;
subtest 'test_me_too' => \&_passing;
subtest 'skip_me'     => \&_failing;
