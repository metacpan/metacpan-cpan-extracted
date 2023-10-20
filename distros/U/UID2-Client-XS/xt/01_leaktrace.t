use strict;
use warnings;
use lib '.';

use Test::More;
use UID2::Client::XS;

use t::TestUtils;

eval 'use Test::LeakTrace 0.08';
plan skip_all => "Test::LeakTrace 0.08 required for testing leak trace" if $@;
plan tests => 1;

my $master_key_id = 164;
my $site_key_id = 165;
my $site_id = 9000;
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
my $client_secret = 'ioG3wKxAokmp+rERx6A4kM/13qhyolUXIu14WN16Spo=';

no_leaks_ok(sub {
    my $client = UID2::Client::XS->new({
        endpoint => 'ep',
        auth_key => 'ak',
        secret_key => $client_secret,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
    });
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    my $result = $client->decrypt($advertising_token);
    my $encrypted = $client->encrypt_data($result->{uid}, { advertising_token => $advertising_token });
    $client->decrypt_data($encrypted->{encrypted_data});
});
