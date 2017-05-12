
use Test::More qw(no_plan);
use Test::Exception;

use UltraDNS;

do 't/util.pl';

my $udns = test_connect();
my $rr;


my ($zone, $domain) = create_test_zone($udns);

$r = $udns->do( $udns->GetZoneInfo("$domain.") );
is ref $r, 'HASH';
is $r->{name}, $zone;
ok $r->{id};

my $id = $r->{id};

#$udns->trace(3);
$r = $udns->do( $rr = $udns->GetAllRRsOfZone($zone) );
#warn Dumper($rr);
#warn Dumper($r);

# test original objects
is ref $$rr, 'RPC::XML::array', 'should be array';
my $rr_value = $$rr->value(1); # no recurse
my %types = map { ref($_) => 1 } @$rr_value;
ok $types{'RPC::XML::soa_record'}, 'should contain a soa_record';
ok $types{'RPC::XML::ns_record'}, 'should contain ns_record';

# test recursively unwrapped values
is ref $r, 'ARRAY';
is ref $r->[0], 'HASH';

# returns 'nil' value, i.e., <param> tag with no <value> tag:
# "<methodResponse><params><param></param></params></methodResponse>"
$r = $udns->do( $udns->GetCNAMERecordsOfZone($zone) );
is $r, undef, 'nil (missing) value should be undef';
