use strict;
use warnings;
use lib '.';

use Test::More;
use Crypt::Misc qw(encode_b64 decode_b64);

use UID2::Client;
use UID2::Client::Key;
use UID2::Client::IdentityScope;
use UID2::Client::DecryptionStatus;
use UID2::Client::Timestamp;

use t::TestUtils;

my $now = UID2::Client::Timestamp->now;
my $master_key = UID2::Client::Key->new(
    id        => 164,
    site_id   => -1,
    created   => $now->add_days(-1)->get_epoch_second,
    activates => $now->get_epoch_second,
    expires   => $now->add_days(1)->get_epoch_second,
    secret    => pack('C32',
        139, 37, 241, 173, 18, 92, 36, 232,
        165, 168, 23, 18, 38, 195, 123, 92,
        160, 136, 185, 40, 91, 173, 165, 221,
        168, 16, 169, 164, 38, 139, 8, 155),
);
my $site_id = 9000;
my $site_key = UID2::Client::Key->new(
    id        => 165,
    site_id   => $site_id,
    created   => $now->add_days(-10)->get_epoch_second,
    activates => $now->add_days(-9)->get_epoch_second,
    expires   => $now->add_days(1)->get_epoch_second,
    secret    => pack('C32',
        32, 251, 7, 194, 132, 154, 250, 86,
        202, 116, 104, 29, 131, 192, 139, 215,
        48, 164, 11, 65, 226, 110, 167, 14,
        108, 51, 254, 125, 65, 24, 23, 133),
);
my $example_uid = 'ywsvDNINiZOVSsfkHpLpSJzXzhr6Jx9Z/4Q0+lsEUvM=';
my $secret_key = 'ioG3wKxAokmp+rERx6A4kM/13qhyolUXIu14WN16Spo=';
my $client_options = {
    endpoint => 'ep',
    auth_key => 'ak',
    secret_key => $secret_key,
    identity_scope => UID2::Client::IdentityScope::UID2,
};

subtest SmokeTest => sub {
    my $client = UID2::Client->new($client_options);
    isa_ok $client, 'UID2::Client';
    my $refresh_result = $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    ok $refresh_result->{is_success};
    my $advertising_token = t::TestUtils::encrypt_token_v2(
        id_str => $example_uid,
        site_id => $site_id,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $result = $client->decrypt($advertising_token);
    ok $result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $result->{uid}, $example_uid;
};

subtest EmptyKeyContainer => sub {
    my $client = UID2::Client->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v2(
        id_str => $example_uid,
        site_id => $site_id,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $result = $client->decrypt($advertising_token);
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::NOT_INITIALIZED;
};

subtest ExpiredKeyContainer => sub {
    my $client = UID2::Client->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v2(
        id_str => $example_uid,
        site_id => $site_id,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $master_key_expired = UID2::Client::Key->new(
        id        => $master_key->id,
        site_id   => -1,
        created   => $now->get_epoch_second,
        activates => $now->add_days(-2)->get_epoch_second,
        expires   => $now->add_days(-1)->get_epoch_second,
        secret    => $master_key->secret,
    );
    my $site_key_expired = UID2::Client::Key->new(
        id        => $site_key->id,
        site_id   => $site_id,
        created   => $now->get_epoch_second,
        activates => $now->add_days(-2)->get_epoch_second,
        expires   => $now->add_days(-1)->get_epoch_second,
        secret    => $site_key->secret,
    );
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key_expired, $site_key_expired));
    my $result = $client->decrypt($advertising_token);
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::KEYS_NOT_SYNCED;
};

subtest NotAuthorizedForKey => sub {
    my $client = UID2::Client->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v2(
        id_str => $example_uid,
        site_id => $site_id,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $another_master_key = UID2::Client::Key->new(
        id        => $master_key->id + $site_key->id + 1,
        site_id   => -1,
        created   => $now->get_epoch_second,
        activates => $now->get_epoch_second,
        expires   => $now->add_days(1)->get_epoch_second,
        secret    => $master_key->secret,
    );
    my $another_site_key = UID2::Client::Key->new(
        id        => $master_key->id + $site_key->id + 2,
        site_id   => $site_id,
        created   => $now->get_epoch_second,
        activates => $now->get_epoch_second,
        expires   => $now->add_days(1)->get_epoch_second,
        secret    => $site_key->secret,
    );
    $client->refresh_json(t::TestUtils::key_set_to_json($another_master_key, $another_site_key));
    my $res = $client->decrypt($advertising_token, $now);
    ok !$res->{is_success};
    is $res->{status}, UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest InvalidPayload => sub {
    my $client = UID2::Client->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v2(
        id_str => $example_uid,
        site_id => $site_id,
        master_key => $master_key,
        site_key => $site_key,
    );
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    is $client->decrypt(substr($advertising_token, 0, length($advertising_token) -3), $now)->{status},
            UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
    is $client->decrypt(substr($advertising_token, 0, length($advertising_token) -4), $now)->{status},
            UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
    is $client->decrypt(substr($advertising_token, 0, 5), $now)->{status},
            UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
};

subtest TokenExpiryAndCustomNow => sub {
    my $expiry = $now->add_days(-6);
    my $client = UID2::Client->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::encrypt_token_v2(
        id_str => $example_uid,
        site_id => $site_id,
        master_key => $master_key,
        site_key => $site_key,
        token_expiry => $expiry,
    );
    my $result = $client->decrypt($advertising_token, $expiry->add_seconds(1));
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::EXPIRED_TOKEN;

    $result = $client->decrypt($advertising_token, $expiry->add_seconds(-1));
    ok $result->{is_success};
    is $result->{uid}, $example_uid;
};

subtest DecryptData => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = t::TestUtils::encrypt_data_v2($data, {
        site_id => $site_id,
        key => $site_key,
        now => $now,
    });
    my $decrypted = $client->decrypt_data($encrypted);
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
    isa_ok $decrypted->{encrypted_at}, 'UID2::Client::Timestamp';
    is $decrypted->{encrypted_at}->get_epoch_milli, $now->get_epoch_milli;
};

subtest BadPayloadType => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = t::TestUtils::encrypt_data_v2($data, {
        site_id => $site_id,
        key => $site_key,
    });
    my $encrypted_bytes = decode_b64($encrypted);
    substr($encrypted_bytes, 0, 1) = 0;
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::INVALID_PAYLOAD_TYPE;
};

subtest BadVersion => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = t::TestUtils::encrypt_data_v2($data, {
        site_id => $site_id,
        key => $site_key,
    });
    my $encrypted_bytes = decode_b64($encrypted);
    substr($encrypted_bytes, 1, 1) = 0;
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::VERSION_NOT_SUPPORTED;
};

subtest BadPayload => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = t::TestUtils::encrypt_data_v2($data, {
        site_id => $site_id,
        key => $site_key,
    });
    my $encrypted_bytes = decode_b64($encrypted);
    my $encrypted_bytes_larger = $encrypted_bytes;
    $encrypted_bytes_larger .= '1';
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes_larger));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::INVALID_PAYLOAD;

    my $encrypted_bytes_smaller = $encrypted_bytes;
    $encrypted_bytes_smaller =~ s/.{2}\z//;
    $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes_smaller));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::INVALID_PAYLOAD;

    $decrypted = $client->decrypt_data(substr($encrypted_bytes, 0, 4));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::INVALID_PAYLOAD;

    $decrypted = $client->decrypt_data($encrypted_bytes . '0');
    is $decrypted->{status}, UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
};

subtest NoDecryptionKey => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = t::TestUtils::encrypt_data_v2($data, {
        site_id => $site_id,
        key => $site_key,,
    });
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key));
    my $decrypted = $client->decrypt_data($encrypted);
    is $decrypted->{status}, UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

done_testing;
