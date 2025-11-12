
#!/usr/bin/env perl
use v5.38;
use WebService::Akeneo;
use WebService::Akeneo::Config;

my $cfg = WebService::Akeneo::Config->new(
  base_url      => $ENV{AKENEO_BASE_URL}      // die "AKENEO_BASE_URL missing\n",
  client_id     => $ENV{AKENEO_CLIENT_ID}     // die "AKENEO_CLIENT_ID missing\n",
  client_secret => $ENV{AKENEO_CLIENT_SECRET} // die "AKENEO_CLIENT_SECRET missing\n",
  username      => $ENV{AKENEO_USER}          // die "AKENEO_USER missing\n",
  password      => $ENV{AKENEO_PASS}          // die "AKENEO_PASS missing\n",
);

my $ak = WebService::Akeneo->new(config => $cfg);

$ak->on_request(sub ($i){ say "--> $i->{method} $i->{url}"; });
$ak->on_response(sub ($i){ say "<-- $i->{code}"; });

my $res = $ak->categories->upsert_ndjson([
  { code=>'mixers',     parent=>'djmania', labels=>{ es_ES=>'Mezcladores' } },
  { code=>'turntables', parent=>'djmania', labels=>{ es_ES=>'Platos' } },
]);

require Data::Dumper; print Data::Dumper::Dumper($res);
