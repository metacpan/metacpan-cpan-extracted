use strict;
use warnings;
use Test::More tests => 1;

use signatures;

my $foo = sub ($bar, $baz) { return "${bar}-${baz}" };

is($foo->(qw/bar baz/), 'bar-baz');
