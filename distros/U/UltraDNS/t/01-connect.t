use strict;
use Test::More qw(no_plan);
use Test::Exception;

use UltraDNS;

do 't/util.pl';

my ($hp,$s,$u,$p) = test_connect_args();

# test bad username/password (sponsor doesn't seem to be checked)
dies_ok { UltraDNS->connect($hp, $s, $u.42, $p) };
like $@, qr/OpenConnection .*failed with .*error/;

dies_ok { UltraDNS->connect($hp, $s, $u, $p.42) };
like $@, qr/OpenConnection .*failed with .*error/;

# test bad host (in this case, the echo service on localhost)
dies_ok { UltraDNS->connect("127.0.0.1:7", $s, $u, $p) };
like $@, qr/Error connecting to/;

# proper connection
my $udns = UltraDNS->connect($hp, $s, $u, $p, { version => '3.0' });
isa_ok $udns, 'UltraDNS';

# test separate simple method call
my $rr = $udns->EnableAutoSerialUpdate;
ok $rr;
is ref $rr, 'SCALAR';
is $$rr, undef;

$udns->commit;
is $$rr->value, 'Method succeeded';

$rr = $udns->GetAutoSerialUpdateState;
$udns->commit;
is $$rr->value, 1;

$rr = $udns->DisableAutoSerialUpdate;
$udns->commit;

$rr = $udns->GetAutoSerialUpdateState;
$udns->commit;
is $$rr->value, 0;

#$udns->trace(3);
# test combined transaction
my @rr1 = (
    $udns->EnableAutoSerialUpdate,      # 0
    $udns->GetAutoSerialUpdateState,    # 1
    $udns->DisableAutoSerialUpdate,     # 2
    $udns->GetAutoSerialUpdateState,    # 3
);
$udns->commit;
#warn Dumper(\@rr1);

is( (${$rr1[1]})->value, 1 );
is( (${$rr1[3]})->value, 0 );


# test combined transaction using do()
my @rr2 = $udns->do(
    $udns->EnableAutoSerialUpdate,      # 0
    $udns->GetAutoSerialUpdateState,    # 1
    $udns->DisableAutoSerialUpdate,     # 2
    $udns->GetAutoSerialUpdateState,    # 3
);
#warn Dumper(\@rr2);

# note that deref and ->value call not needed when using do()
is( $rr2[1], 1 );
is( $rr2[3], 0 );


# test combined transaction using eval()
my @rr3 = $udns->eval(
    $udns->EnableAutoSerialUpdate,      # 0
    $udns->GetAutoSerialUpdateState,    # 1
    $udns->DisableAutoSerialUpdate,     # 2
    $udns->GetAutoSerialUpdateState,    # 3
);
#warn Dumper(\@rr3);

is_deeply(\@rr3, \@rr2);


