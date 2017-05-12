use Test::More qw(no_plan);
BEGIN { use_ok('Tie::Scalar::Epoch') };

tie my $epoch, 'Tie::Scalar::Epoch';
isa_ok(tied($epoch), 'Tie::Scalar::Epoch');

my $e1 = $epoch;
sleep 1;
my $e2 = $epoch;

isnt($e1, $e2, 'Should not match');


eval { $epoch = '123' };   # this should die
like($@, qr/Can't store/, "Assigning to epoch should die");


tied($epoch)->{no_die} = 1;
eval { $^W = 0; $epoch = '123' };   # now this SHOULDN'T die
is($@, '', 'Option no_die stops death on assignment');
