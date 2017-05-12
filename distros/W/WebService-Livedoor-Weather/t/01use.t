use Test::More tests => 5;
BEGIN { use_ok('WebService::Livedoor::Weather') };

my $lwws = WebService::Livedoor::Weather->new();

isa_ok($lwws, "WebService::Livedoor::Weather");
can_ok($lwws, "get");
can_ok($lwws, "__get_cityid");
can_ok($lwws, "__forecastmap");


