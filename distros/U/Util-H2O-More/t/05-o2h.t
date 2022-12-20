use strict;
use warnings;

use Test::More q//;
use Util::H2O::More qw/h2o o2h/;

# for included module required for testing
use FindBin qw/$Bin/;
use lib qq{$Bin/lib};
use Foo;

my $origin_ref = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

my $ref = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

h2o $ref;

is_deeply o2h($ref), $origin_ref, q{'o2h' does inverse of h2o};
is ref o2h($ref), q{HASH}, q{making sure test ref really is just a 'HASH'};

my $ref2 = o2h $ref;

h2o -recurse, $ref2;
is_deeply o2h($ref2), $origin_ref, q{'o2h' does inverse of 'h2o --recurse'};

my $ref3 = o2h $ref2;

# composing h2o/o2h in one line
is_deeply o2h(h2o $ref3), $origin_ref, q{'o2h' does inverse of 'h2o --recurse'};

my $foo = Foo->new(a => 1);
is ref o2h($foo), q{HASH}, q{'o2h' works on baptised module-based object};

my $_foo = {
    somewhere => q{over},
    the       => { rainbow => { way => { out => q{there} } } },
};

my $foo2 = o2h(Foo->new(%$_foo));

is_deeply $foo2, $_foo, q{'o2h' does invere of a package built with 'baptise -recurse'};

done_testing;
