use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'Tie::Hash::Regex' };

my %hash : Regex;

$hash{key} = 'value';
$hash{key2} = 'another value';
$hash{stuff} = 'something else';

my $x = 'f';

is($hash{key}, 'value');
is($hash{'^s'}, 'something else');
is($hash{qr'^s'}, 'something else');
ok(not defined $hash{blah});
is($hash{$x}, 'something else');

my @vals = tied(%hash)->FETCH('k');
is(@vals, 2);
delete $hash{stuff};
is(keys %hash, 2);

ok(exists $hash{key});
ok(exists $hash{k});
ok(exists $hash{qr'^k'});
ok(not exists $hash{zz});

delete $hash{2};
my @k = keys %hash;
is(@k, 1);
delete $hash{qr/^k/};
ok(not keys %hash);

done_testing();
