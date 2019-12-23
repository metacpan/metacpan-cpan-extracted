use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings ':no_end_test', 'warnings';

my $e;
my $no_warn_sub;
my $warn_sub;
{
    no warnings;
    if (!eval q{
        $no_warn_sub = sub { return 1 + undef };
        BEGIN { warnings->import }
        $warn_sub = sub { return 1 + undef };
        1;
    }) {
        $e = $@;
    }
}

is $e, undef,
    'warnings->import succeeds after importing "warnings" sub';

ok !warnings { $no_warn_sub->() },
    'no warnings worked as expected';

like +(warnings { $warn_sub->() })[0], qr{uninitialized value},
    'correct warnings were enabled after warnings->import';

done_testing;
