# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::Simple tests => 11;

use Tie::Hash::FixedKeys;
ok(1);

my %hash : FixedKeys(qw(one two three));

$hash{one} = 1;
ok($hash{one} == 1);
$hash{two} = 2;
ok($hash{two} == 2);

eval { $hash{four} = 4 };
ok(not defined $hash{four});
ok(not exists $hash{four});

delete $hash{one};
ok(not defined $hash{one});
ok(exists $hash{one});

delete $hash{four};
ok(not defined $hash{four});
ok(not exists $hash{four});

%hash = ();
ok(not defined $hash{one});
ok(exists $hash{one});
