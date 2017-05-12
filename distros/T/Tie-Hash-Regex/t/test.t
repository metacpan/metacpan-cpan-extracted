use Test::More tests=> 14;

BEGIN { use_ok 'Tie::Hash::Regex' };

my %hash : Regex;

$hash{key} = 'value';
$hash{key2} = 'another value';
$hash{stuff} = 'something else';

my $x = 'f';

ok($hash{key} eq 'value');
ok($hash{'^s'} eq 'something else');
ok($hash{qr'^s'} eq 'something else');
ok(not defined $hash{blah});
ok($hash{$x} eq 'something else');

my @vals = tied(%hash)->FETCH('k');
ok(@vals == 2);
delete $hash{stuff};
ok(keys %hash == 2);

ok(exists $hash{key});
ok(exists $hash{k});
ok(exists $hash{qr'^k'});
ok(not exists $hash{zz});

delete $hash{2};
my @k = keys %hash;
ok(@k == 1);
delete $hash{qr/^k/};
ok(not keys %hash);

