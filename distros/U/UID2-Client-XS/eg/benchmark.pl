#!/usr/bin/env perl
use strict;
use warnings;

use lib '.';
use t::TestUtils;

use Benchmark qw(:all);

use UID2::Client::XS;
use UID2::Client::XS::IdentityScope;
use UID2::Client::XS::IdentityType;
use UID2::Client::XS::Timestamp;

use UID2::Client;

my $master_key_id = 164;
my $site_key_id = 165;
my $site_id = 9000;
my $site_id2 = 2;
my $master_secret = pack('C32',
    139, 37, 241, 173, 18, 92, 36, 232,
    165, 168, 23, 18, 38, 195, 123, 92,
    160, 136, 185, 40, 91, 173, 165, 221,
    168, 16, 169, 164, 38, 139, 8, 155,
);
my $site_secret = pack('C32',
    32, 251, 7, 194, 132, 154, 250, 86,
    202, 116, 104, 29, 131, 192, 139, 215,
    48, 164, 11, 65, 226, 110, 167, 14,
    108, 51, 254, 125, 65, 24, 23, 133,
);
my $now = UID2::Client::XS::Timestamp->now();
my $master_key = {
    id        => $master_key_id,
    site_id   => -1,
    created   => $now->add_days(-1),
    activates => $now,
    expires   => $now->add_days(1),
    secret    => $master_secret,
};
my $site_key = {
    id        => $site_key_id,
    site_id   => $site_id,
    created   => $now->add_days(-10),
    activates => $now->add_days(-9),
    expires   => $now->add_days(1),
    secret    => $site_secret,
};
my $example_uid = 'ywsvDNINiZOVSsfkHpLpSJzXzhr6Jx9Z/4Q0+lsEUvM=';
my $secret_key = 'ioG3wKxAokmp+rERx6A4kM/13qhyolUXIu14WN16Spo=';

my $advertising_token = t::TestUtils::encrypt_token_v3(
    id_str => $example_uid,
    site_id => $site_id,
    identity_type => UID2::Client::XS::IdentityType::EMAIL,
    identity_scope => UID2::Client::XS::IdentityScope::UID2,
    master_key => { id => $master_key_id, secret => $master_key->{secret} },
    site_key => { id => $site_key_id, secret => $site_key->{secret} },
);
my $json = t::TestUtils::key_set_to_json($master_key, $site_key);

my $xs = UID2::Client::XS->new({
    endpoint => 'ep',
    auth_key => 'ak',
    secret_key => $secret_key,
});
$xs->refresh_json($json);
my $pp = UID2::Client->new({
    endpoint => 'ep',
    auth_key => 'ak',
    secret_key => $secret_key,
});
$pp->refresh_json($json);

my $count = $ARGV[0] // 200_000;
cmpthese(timethese($count, {
    'decrypt-PP' => sub {
        my $pp_result = $pp->decrypt($advertising_token);
    },
    'decrypt-XS' => sub {
        my $xs_result = $xs->decrypt($advertising_token);
    },
}));
cmpthese(timethese($count, {
    'refresh_json-PP' => sub {
        my $pp_result = $pp->refresh_json($json);
    },
    'refresh_json-XS' => sub {
        my $xs_result = $xs->refresh_json($json);
    },
}));

__END__
# MacBook Pro (13-inch, 2020, Four Thunderbolt 3 ports)
# Processor: 2.3 GHz Quad-Core Intel Core i7
# Memory: 32 GB 3733 MHz LPDDR4X

Benchmark: timing 200000 iterations of decrypt-PP, decrypt-XS...
decrypt-PP: 14 wallclock secs (14.11 usr +  0.04 sys = 14.15 CPU) @ 14134.28/s (n=200000)
decrypt-XS:  2 wallclock secs ( 2.18 usr +  0.00 sys =  2.18 CPU) @ 91743.12/s (n=200000)
              Rate decrypt-PP decrypt-XS
decrypt-PP 14134/s         --       -85%
decrypt-XS 91743/s       549%         --

Benchmark: timing 200000 iterations of refresh_json-PP, refresh_json-XS...
refresh_json-PP:  2 wallclock secs ( 1.91 usr +  0.01 sys =  1.92 CPU) @ 104166.67/s (n=200000)
refresh_json-XS:  9 wallclock secs ( 8.16 usr +  0.02 sys =  8.18 CPU) @ 24449.88/s (n=200000)
                    Rate refresh_json-XS refresh_json-PP
refresh_json-XS  24450/s              --            -77%
refresh_json-PP 104167/s            326%              --
