use Test::More tests => 10;
use Tie::Scalar::Timeout;
tie my $k, 'Tie::Scalar::Timeout', EXPIRES => '+2s';
$k = 123;
is($k, 123, 'assigned value');
sleep(3);
ok(!defined($k), 'value timed out');

# test assigning via tie() and num_uses
tie my $m, 'Tie::Scalar::Timeout', NUM_USES => 3, VALUE => 456;
is($m, 456, 'assigned value via tie()');
for (0 .. 2) { my $tmp = $m }
ok(!defined($m), 'value reset after 3 uses');

# test reassigning a value so num_uses is reset
$m = 789;
is($m, 789, 'reassigned value');
for (0 .. 2) { my $tmp = $m }
ok(!defined($m), 'value reset again after 3 uses');

# test a fixed-value expiration policy
tie my $n, 'Tie::Scalar::Timeout', VALUE => 987, NUM_USES => 1, POLICY => 777;
is($n, 987, 'assigned value via tie()');
is($n, 777, 'fixed-value expiration policy');

# test a coderef expiration policy
tie my $p, 'Tie::Scalar::Timeout',
  VALUE    => 654,
  NUM_USES => 1,
  POLICY   => \&expired;
my $is_expired;
sub expired { $is_expired++ }
is($p, 654, 'assigned value via tie()');
$_ = $p;    # to activate FETCH
ok($is_expired, 'coderef expiration policy');
