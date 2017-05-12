use strict;
use Test::More;
use Test::Fixture::KyotoTycoon;
use Cache::KyotoTycoon;
use YAML::XS qw(LoadFile);

my $fixture_yaml = "t/fixture.yaml";
my $arrayref     = LoadFile($fixture_yaml);

eval "use Test::TCP";
if ($@) {
	plan skip_all => 'Test::TCP does not installed. skip all';
}
eval "use Data::MessagePack";
if ($@) {
	plan skip_all => 'Data::MessagePack does not installed. skip all';
}

# find kyototycoon
chomp(my $kt_bin = readpipe "which ktserver 2>/dev/null");
my $exit_value = $? >> 8;
if ($exit_value != 0) {
	$kt_bin = $ENV{KYOTOTYCOON_PATH};
}

if(!$kt_bin) {
	plan skip_all => 'ktserver can not find. If it is installed in a location path is not passed, set the case kyototycoon path to KYOTOTYCOON_PATH environ variable';
}

my $kyototycoon = Test::TCP->new(
	code => sub {
		my $port = shift;
		exec "$kt_bin -host 127.0.0.1 -port $port -log /dev/null";
		die "cannot execute $kt_bin: $!";
	},
	port => Test::TCP::empty_port(11978)
);

my $kt = Cache::KyotoTycoon->new(host => "127.0.0.1", port => $kyototycoon->port);
my $serializer = sub { 
	my $ref = shift;
	return Data::MessagePack->pack($ref);
};

foreach my $src ($fixture_yaml, $arrayref) {
	construct_fixture kt => $kt, fixture => $src, serializer => $serializer;

	my $data = $kt->get("array");
        my $array = Data::MessagePack->unpack($data);
	is ref($array), "ARRAY", "array is ARRAY reference";
	is_deeply $array, [1,2,3,4,5], "array deep match";
	# hash
	$data = $kt->get("hash");
        my $hash = Data::MessagePack->unpack($data);
	is ref($hash), "HASH", "hash is HASH reference";
	is_deeply $hash, { apple => "red", banana => "yellow" }, "hash deep match";
}

done_testing;
