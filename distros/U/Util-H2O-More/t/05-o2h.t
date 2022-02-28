use strict;
use warnings;

use Test::More q//;

use Util::H2O::More qw/h2o o2h/;

my $origin_ref = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

my $ref = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

h2o $ref;

is_deeply o2h($ref), $origin_ref, q{o2h does inverse of h2o};
is ref o2h($ref), q{HASH}, q{making sure test ref really is just a 'HASH'};

my $ref2 = o2h $ref;

h2o -recurse, $ref2;
is_deeply o2h(-recurse, $ref2), $origin_ref, q{'o2h --recurse' does inverse of 'h2o --recurse'};

my $ref3 = o2h -recurse, $ref2;

# composing h2o/o2h in one line
is_deeply o2h(-recurse, h2o $ref3), $origin_ref, q{'o2h --recurse' does inverse of 'h2o --recurse'};

done_testing;
