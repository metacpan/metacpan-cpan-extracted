use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);
use lib 'lib';
use eBay::Client::OpenAPI3;

my ($fh, $config) = tempfile();
print {$fh} <<'EOF_CONFIG';
[eBay]
client_id = client-123
client_secret = secret-456
affiliateCampaignId = 1234567890
affiliateReferenceId = existing-but-unused
EOF_CONFIG
close $fh;

my $client = eBay::Client::OpenAPI3->new(config => $config);
isa_ok($client, 'eBay::Client::OpenAPI3');
is($client->config->eBay->client_id, 'client-123', 'constructor reads client ID');
is($client->config->eBay->client_secret, 'secret-456', 'constructor reads client secret');
is($client->config->eBay->affiliateCampaignId, '1234567890', 'constructor preserves campaign ID');
is($client->config->eBay->affiliateReferenceId, 'existing-but-unused', 'constructor preserves reference ID');
ok(!defined $client->token, 'token starts undefined');
ok(!defined $client->next, 'next starts undefined');
ok(!defined $client->total, 'total starts undefined');

eval { eBay::Client::OpenAPI3->new(config => "$config.missing") };
like($@, qr/configuration file not found/, 'missing configuration file is rejected as before');

my %defined = eBay::Client::OpenAPI3::_defined_params(
    a => 1,
    b => undef,
    c => 0,
    d => q{},
);
is_deeply(
    \%defined,
    { a => 1, c => 0, d => q{} },
    'undefined query values are omitted and defined false values retained',
);

is(
    eBay::Client::OpenAPI3::_error_message_from_json(
        { errors => [ { longMessage => 'hash error' } ] }
    ),
    'hash error',
    'error helper handles hash data',
);

is(
    eBay::Client::OpenAPI3::_error_message_from_json({}),
    'Unknown error',
    'error helper has stable fallback',
);

my $warnings = q{};
{
    local $SIG{__WARN__} = sub { $warnings .= join q{}, @_ };
    $client->warn_if_exists({ foo => 'bar' }, 'foo');
    $client->warn_if_exists({ foo => 'bar' }, 'missing');
}
like($warnings, qr/'foo' detected: bar/, 'present response header is warned');
unlike($warnings, qr/missing/, 'absent response header is ignored');

{
    package Local::UASeam;
    our @ISA = ('eBay::Client::OpenAPI3');
    our @OPTS;
    sub _new_ua {
        my ($self, %opts) = @_;
        push @OPTS, { %opts };
        return bless {}, 'Local::NoopUA';
    }
}

my $seam = Local::UASeam->new(config => $config);
$seam->token(Util::H2O::More::d2o({ access_token => 'TOKEN' }));
my $ua = $seam->get_ua;
isa_ok($ua, 'Local::NoopUA');
my $opts = $Local::UASeam::OPTS[-1];
is($opts->{default_headers}{Authorization}, 'Bearer TOKEN', 'bearer header unchanged');
is($opts->{default_headers}{'X-EBAY-C-MARKETPLACE-ID'}, 'EBAY_US', 'marketplace header unchanged');
is(
    $opts->{default_headers}{'X-EBAY-C-ENDUSERCTX'},
    'affiliateCampaignId=1234567890',
    'EPN context remains campaign-only for compatibility',
);
ok(
    !defined $opts->{content},
    'HTTP::Tiny construction retains content option semantics',
);

done_testing;
