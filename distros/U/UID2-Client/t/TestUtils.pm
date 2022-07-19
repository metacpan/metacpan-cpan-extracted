package t::TestUtils;
use strict;
use warnings;

use Test::MockObject;
use Carp;
use JSON;
use Crypt::Mode::CBC;
use Crypt::AuthEnc::GCM;
use Crypt::Misc qw(encode_b64 decode_b64);
use Crypt::PRNG qw(random_bytes irand);

use UID2::Client::Decryption;
use UID2::Client::IdentityType;
use UID2::Client::Timestamp;

sub encrypt_token_v2 {
    my %args = @_;
    my $privacy_bits = irand();
    my $established = UID2::Client::Timestamp->now->add_seconds(-60 * 60);
    my $identity = pack 'N! N! a* N! q>',
            $args{site_id}, length($args{id_str}), $args{id_str},
            $privacy_bits, $established->get_epoch_milli;
    my $identity_iv = random_bytes(16);

    my $expires = $args{token_expiry} // UID2::Client::Timestamp->now->add_seconds(60 * 60);
    my $master_payload = pack 'q> a*', $expires->get_epoch_milli,
            _encrypt_cbc($identity, $args{site_key}, $identity_iv);
    my $master_iv = random_bytes(16);

    my $version = 2;
    my $token = pack 'C a*', $version, _encrypt_cbc($master_payload, $args{master_key}, $master_iv);
    encode_b64($token);
}

sub encrypt_token_v3 {
    my %args = @_;

    # publisher data
    my $publisher_id = 0;
    my $client_key_id = 0;
    my $site_payload = pack 'N! q> N!', $args{site_id}, $publisher_id, $client_key_id;

    # user identity data
    my $privacy_bits = irand();
    my $established = UID2::Client::Timestamp->now->add_seconds(-60 * 60);
    my $refreshed = UID2::Client::Timestamp->now->add_seconds(-40 * 60);
    my $identity_bytes = decode_b64($args{id_str});

    $site_payload .= pack 'N! q> q> a*', $privacy_bits, $established->get_epoch_milli,
            $refreshed->get_epoch_milli, $identity_bytes;
    my $site_iv = random_bytes(12);
    my $site_payload_encrypted = _encrypt_gcm($site_payload, $args{site_key}, $site_iv);

    # operator data
    my $operator_site_id = 0;
    my $operator_type = 0;
    my $operator_version = 0;
    my $operator_key_id = 0;

    my $expires = $args{token_expiry} // UID2::Client::Timestamp->now->add_seconds(60 * 60);
    my $created = UID2::Client::Timestamp->now;
    my $master_payload = pack 'q> q> N! C N! N! a*', $expires->get_epoch_milli, $created->get_epoch_milli,
            $operator_site_id, $operator_type, $operator_version, $operator_key_id,
            $site_payload_encrypted;
    my $master_iv = random_bytes(12);
    my $master_payload_encrypted = _encrypt_gcm($master_payload, $args{master_key}, $master_iv);

    my $identity_type = $args{identity_type} // UID2::Client::IdentityType::EMAIL;
    my $identity_scope_and_type = ($args{identity_scope} << 4) | ($identity_type << 2);
    my $version = 112;
    my $token = pack 'C C a*', $identity_scope_and_type, $version, $master_payload_encrypted;
    encode_b64($token);
}

sub encrypt_data_v2 {
    my ($data, $args) = @_;
    my $keys = $args->{keys};
    my $key = $args->{key};
    if ($keys && $key) {
        croak 'only one of keys and key can be specified';
    }
    my $site_id;
    if (!$key) {
        $site_id = $args->{site_id};
        my $advertising_token = $args->{advertising_token};
        if ($site_id && $advertising_token) {
            croak 'only one of site_id and advertising_token can be specified';
        }
        if ($advertising_token) {
            my $token = UID2::Client::Decryption::decrypt($advertising_token, $keys);
            $site_id = $token->{site_id};
        }
        $key = $keys->get_active_site_key($site_id);
        unless ($key) {
            croak 'no key for the specified site';
        }
    } elsif (!$key->is_active) {
        croak 'key is either expired or not active yet';
    } else {
        $site_id = $key->site_id;
    }
    my $iv = $args->{iv} // random_bytes(16);
    my $res = pack 'C C q> N! a*', (
        128,
        1,
        ($args->{now} // UID2::Client::Timestamp->now)->get_epoch_milli,
        $site_id,
        _encrypt_cbc($data, $key, $iv),
    );
    encode_b64($res);
}

sub _encrypt_cbc {
    my ($data, $key, $iv) = @_;
    my $cipher = Crypt::Mode::CBC->new('AES');
    pack 'N! a16 a*', $key->id, $iv, $cipher->encrypt($data, $key->secret, $iv);
}

sub _encrypt_gcm {
    my ($data, $key, $iv) = @_;
    my $ae = Crypt::AuthEnc::GCM->new('AES', $key->secret, $iv);
    my $ciphertext = $ae->encrypt_add($data);
    $ciphertext .= $ae->encrypt_done();
    pack 'N! a12 a*', $key->id, $iv, $ciphertext;
}

sub mock_http {
    my ($secret_key, @keys) = @_;
    my $secret_key_bytes = decode_b64($secret_key);
    my $json = key_set_to_json(@keys);
    my $http = Test::MockObject->new;
    $http->mock(post => sub {
        my ($self, $url, $params) = @_;
        # fake server
        my ($version, $payload) = unpack 'a a*', decode_b64($params->{content});
        die 'invalid version' if ord($version) != 1;
        my $decrypted = UID2::Client::Decryption::decrypt_gcm($payload, $secret_key_bytes);
        my ($nonce) = unpack 'x8 a8', $decrypted;
        my $now = UID2::Client::Timestamp->now;
        my $envelope = pack 'q> a8 a*', $now->get_epoch_milli, $nonce, $json;
        my $envelope_encrypted = UID2::Client::Decryption::encrypt_gcm($envelope, $secret_key_bytes);
        my $content = encode_b64($envelope_encrypted);
        +{
            success => 1,
            status  => 200,
            content => $content,
        };
    });
    $http;
}

sub key_set_to_json {
    my @keys = @_;
    encode_json({ body => [
        map {
            my $key = $_;
            +{
                (map { $_ => $key->$_() } qw(id site_id created activates expires)),
                secret => encode_b64($key->secret),
            }
        } @keys
    ] });
}

1;
__END__
