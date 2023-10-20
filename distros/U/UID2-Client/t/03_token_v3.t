use strict;
use warnings;
use lib '.';

use Test::More;

use Crypt::Misc qw(encode_b64 decode_b64);

use UID2::Client;
use UID2::Client::Key;
use UID2::Client::KeyContainer;
use UID2::Client::DecryptionStatus;
use UID2::Client::EncryptionStatus;
use UID2::Client::IdentityScope;
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
my $site_id2 = 2;
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
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    isa_ok $client, 'UID2::Client';
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $result = $client->decrypt($advertising_token);
    ok $result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $result->{uid}, $example_uid;
    is $result->{site_id}, $site_id;
    is $result->{site_key_site_id}, $site_id;
    isa_ok $result->{established}, 'UID2::Client::Timestamp';
};

subtest EmptyKeyContainer => sub {
    my $client = UID2::Client->new($client_options);
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $result = $client->decrypt($advertising_token);
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::NOT_INITIALIZED;
};

subtest ExpiredKeyContainer => sub {
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
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
    $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key_expired, $site_key_expired),
    });
    $client->refresh;
    my $result = $client->decrypt($advertising_token);
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::DecryptionStatus::KEYS_NOT_SYNCED;
};

subtest NotAuthorizedForKey => sub {
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $another_master_key = UID2::Client::Key->new(
        id        => $master_key->id + $site_key->id + 1,
        site_id   => -1,
        created   => $now->get_epoch_second,
        activates => $now->add_days(-2)->get_epoch_second,
        expires   => $now->add_days(-1)->get_epoch_second,
        secret    => $master_key->secret,
    );
    my $another_site_key = UID2::Client::Key->new(
        id        => $master_key->id + $site_key->id + 2,
        site_id   => $site_id,
        created   => $now->get_epoch_second,
        activates => $now->add_days(2)->get_epoch_second,
        expires   => $now->add_days(1)->get_epoch_second,
        secret    => $site_key->secret,
    );
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $another_master_key, $another_site_key),
    });
    $client->refresh;
    my $res = $client->decrypt($advertising_token);
    ok !$res->{is_success};
    is $res->{status}, UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest InvalidPayload => sub {
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $master_key,
    );
    is $client->decrypt(substr($advertising_token, 0, length($advertising_token) -3))->{status},
            UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
    is $client->decrypt(substr($advertising_token, 0, length($advertising_token) -4))->{status},
            UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
    is $client->decrypt(substr($advertising_token, 0, 5), $now)->{status},
            UID2::Client::DecryptionStatus::INVALID_PAYLOAD;
};

subtest TokenExpiryAndCustomNow => sub {
    my $expiry = $now->add_days(-6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
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

subtest SpecificKeyAndIv => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $iv = pack 'C12', map { 0 } 1..12;
    my $encrypted = $client->encrypt_data($data, { key => $site_key, initialization_vector => $iv });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest SpecificKeyAndGeneratedIv => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $encrypted = $client->encrypt_data($data, { key => $site_key });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest SpecificSiteId => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest SiteIdFromToken => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $site_key),
    });
    $client->refresh;
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest SiteIdFromTokenCustomSiteKeySiteId => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id2,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest SiteIdAndTokenSet => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
    );
    my $encrypted = $client->encrypt_data($data, {
        advertising_token => $advertising_token,
        site_id => $site_id,
    });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::ENCRYPTION_FAILURE;
};

subtest MultipleSiteKeys => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $make_key = sub {
        my @values = @_;
        my @fields = qw(id site_id created activates expires secret);
        UID2::Client::Key->new(
            map {
                $fields[$_] => ref($values[$_]) ? $values[$_]->get_epoch_second : $values[$_]
            } (0 .. scalar(@fields) - 1)
        );
    };
    my $make_key_secret = sub { pack 'C32', map { $_[0] } 1..32 };
    my @keys = (
        &$make_key(0, $site_id, $now, $now->add_days( 3), $now->add_days(10), &$make_key_secret(0)),
        &$make_key(1, $site_id, $now, $now->add_days(-4), $now->add_days(10), &$make_key_secret(1)),
        &$make_key(2, $site_id, $now, $now->add_days(-2), $now->add_days(10), &$make_key_secret(2)),
        &$make_key(3, $site_id, $now, $now->add_days(-4), $now->add_days(-3), &$make_key_secret(3)),
        &$make_key(4, $site_id, $now, $now->add_days(-4), $now->add_days( 1), &$make_key_secret(4)),
        &$make_key(5, $site_id, $now, $now->add_days(-5), $now->add_days( 2), &$make_key_secret(5)),
        &$make_key(6, $site_id, $now, $now->add_days(-1), $now->add_days( 2), &$make_key_secret(6)),
    );
    my $test = sub {
        my ($now, $key) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $client = UID2::Client->new({
            %$client_options,
            http => t::TestUtils::mock_http($secret_key, @keys),
        });
        $client->refresh;
        my $encrypted = $client->encrypt_data($data, { site_id => $site_id, now => $now });
        is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
        $client = UID2::Client->new({
            %$client_options,
            http => t::TestUtils::mock_http($secret_key, $key),
        });
        $client->refresh;
        my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
        is $decrypted->{status}, UID2::Client::DecryptionStatus::SUCCESS;
        is $decrypted->{decrypted_data}, $data;
    };
    &$test($now->add_days(-5), $keys[5]);
    &$test($now->add_days(-4), $keys[4]);
    &$test($now->add_days(-3), $keys[4]);
    &$test($now->add_days(-2), $keys[2]);
    &$test($now->add_days(-1), $keys[6]);
    &$test($now->add_days( 0), $keys[6]);
    &$test($now->add_days( 1), $keys[6]);
    &$test($now->add_days( 2), $keys[2]);
    &$test($now->add_days( 3), $keys[0]);
};

subtest TokenDecryptFailed => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { advertising_token => 'bogus-token' });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::TOKEN_DECRYPT_FAILURE;
};

subtest KeyExpired => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $key = UID2::Client::Key->new(
        id        => $site_key->id,
        site_id   => $site_id,
        created   => $now->get_epoch_second,
        activates => $now->get_epoch_second,
        expires   => $now->add_days(-1)->get_epoch_second,
        secret    => $site_key->secret,
    );
    my $encrypted = $client->encrypt_data($data, { key => $key });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::KEY_INACTIVE;
};

subtest TokenDecryptKeyExpired => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $key = UID2::Client::Key->new(
        id        => $site_key->id,
        site_id   => $site_id2,
        created   => $now->get_epoch_second,
        activates => $now->get_epoch_second,
        expires   => $now->add_days(-1)->get_epoch_second,
        secret    => $site_key->secret,
    );
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $key));
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $key,
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest KeyInactive => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $key = UID2::Client::Key->new(
        id        => $site_key->id,
        site_id   => $site_id,
        created   => $now->get_epoch_second,
        activates => $now->add_days(1)->get_epoch_second,
        expires   => $now->add_days(2)->get_epoch_second,
        secret    => $site_key->secret,
    );
    my $encrypted = $client->encrypt_data($data, { key => $key });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::KEY_INACTIVE;
};

subtest KeyExpiredCustomNow => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $now = UID2::Client::Timestamp->from_epoch_second($site_key->expires);
    my $encrypted = $client->encrypt_data($data, { key => $site_key, now => $now });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::KEY_INACTIVE;
};

subtest KeyInactiveCustomNow => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new($client_options);
    my $now = UID2::Client::Timestamp->from_epoch_second($site_key->activates)->add_seconds(-1);
    my $encrypted = $client->encrypt_data($data, { key => $site_key, now => $now });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::KEY_INACTIVE;
};

subtest NoSiteKey => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id2 });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest SiteKeyExpired => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $key = UID2::Client::Key->new(%$site_key, expires => $now->add_days(-1)->get_epoch_second);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest SiteKeyInactive => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $key = UID2::Client::Key->new(%$site_key, activates => $now->add_days(1)->get_epoch_second);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest SiteKeyInactiveCustomNow => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $key = UID2::Client::Key->new(%$site_key, activates => $now->add_days(1)->get_epoch_second);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, {
        site_id => $site_id,
        now => UID2::Client::Timestamp->from_epoch_second($site_key->activates)->add_seconds(-1),
    });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest TokenExpired => sub {
    my $expiry = $now->add_days(-6);
    my %params = (token_expiry => $expiry);
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $advertising_token = t::TestUtils::generate_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_scope => UID2::Client::IdentityScope::UID2,
        master_key => $master_key,
        site_key => $site_key,
        %params,
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::TOKEN_DECRYPT_FAILURE;

    $encrypted = $client->encrypt_data($data, {
        advertising_token => $advertising_token,
        now => $expiry->add_seconds(-1),
    });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest BadPayloadType => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { key => $site_key });
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    my $encrypted_bytes = decode_b64($encrypted->{encrypted_data});
    substr($encrypted_bytes, 0, 1) = 0;
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::INVALID_PAYLOAD_TYPE;
};

subtest BadVersion => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { key => $site_key });
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    my $encrypted_bytes = decode_b64($encrypted->{encrypted_data});
    substr($encrypted_bytes, 1, 1) = 0;
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes));
    is $decrypted->{status}, UID2::Client::DecryptionStatus::VERSION_NOT_SUPPORTED;
};

subtest BadPayload => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { key => $site_key });
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    my $encrypted_bytes = decode_b64($encrypted->{encrypted_data});
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
    my $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $site_key),
    });
    $client->refresh;
    my $encrypted = $client->encrypt_data($data, { key => $site_key });
    is $encrypted->{status}, UID2::Client::EncryptionStatus::SUCCESS;
    $client = UID2::Client->new({
        %$client_options,
        http => t::TestUtils::mock_http($secret_key, $master_key),
    });
    $client->refresh;
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    is $decrypted->{status}, UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

done_testing;
