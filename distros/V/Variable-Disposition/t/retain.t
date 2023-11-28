use strict;
use warnings;

use Test::More;
use Test::Refcount;
use Variable::Disposition qw(retain dispose);

my $copy;
{
    my $x = [];
    Scalar::Util::weaken($copy = $x);
    ok($x, 'have a variable');
    is_refcount($x, 1, 'refcount is now 1');
    Scalar::Util::weaken($copy = $x);
    is_refcount($x, 1, 'refcount is still 1');
    retain($x);
    is_refcount($x, 2, 'refcount is now 2');
}
is_refcount($copy, 1, 'refcount is still 1');
ok($copy, 'copy still exists');
dispose($copy);
is($copy, undef, 'copy went away');

done_testing;


