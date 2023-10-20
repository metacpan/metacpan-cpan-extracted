package t::TestUtils;
use strict;
use warnings;

use Crypt::Mode::CBC;
use Crypt::AuthEnc::GCM;
use Crypt::Misc qw(encode_b64 encode_b64u decode_b64);
use Crypt::PRNG qw(random_bytes irand);
use JSON::PP;

use UID2::Client::XS;
use UID2::Client::XS::AdvertisingTokenVersion;
use UID2::Client::XS::Timestamp;

sub generate_token_v2 {
    my %args = @_;
    my $privacy_bit = irand();
    my $established = UID2::Client::XS::Timestamp->now->add_seconds(-60 * 60);
    my $identity = pack 'N! N! a* N! q>',
            $args{site_id}, length($args{id_str}), $args{id_str}, $privacy_bit, $established->get_epoch_milli;
    my $identity_iv = random_bytes(16);

    my $expires = $args{token_expiry} ? $args{token_expiry} : UID2::Client::XS::Timestamp->now->add_seconds(60 * 60);
    my $master_payload = pack 'q> a*', $expires->get_epoch_milli, _encrypt_cbc($identity, $args{site_key}, $identity_iv);
    my $master_iv = random_bytes(16);

    my $version = 2;
    my $token = pack 'C a*', $version, _encrypt_cbc($master_payload, $args{master_key}, $master_iv);
    encode_b64($token);
}

sub generate_token_v3 {
    _generate_token(@_, token_version => UID2::Client::XS::AdvertisingTokenVersion::V3);
}

sub generate_token_v4 {
    _generate_token(@_, token_version => UID2::Client::XS::AdvertisingTokenVersion::V4);
}

sub _generate_token {
    my %args = @_;

    # publisher data
    my $publisher_id = 0;
    my $client_key_id = 0;
    my $site_payload = pack 'N! q> N!', $args{site_id}, $publisher_id, $client_key_id;

    # user identity data
    my $privacy_bits = irand();
    my $established = UID2::Client::XS::Timestamp->now->add_seconds(-60 * 60);
    my $refreshed = UID2::Client::XS::Timestamp->now->add_seconds(-40 * 60);
    my $identity_bytes = decode_b64($args{id_str});

    $site_payload .= pack 'N! q> q> a*', $privacy_bits, $established->get_epoch_milli, $refreshed->get_epoch_milli, $identity_bytes;
    my $site_iv = random_bytes(12);
    my $site_payload_encrypted = _encrypt_gcm($site_payload, $args{site_key}, $site_iv);

    # operator data
    my $operator_site_id = 0;
    my $operator_type = 0;
    my $operator_version = 0;
    my $operator_key_id = 0;

    my $expires = $args{token_expiry} ? $args{token_expiry} : UID2::Client::XS::Timestamp->now->add_seconds(60 * 60);
    my $created = UID2::Client::XS::Timestamp->now;
    my $master_payload = pack 'q> q> N! C N! N! a*', $expires->get_epoch_milli, $created->get_epoch_milli,
            $operator_site_id, $operator_type, $operator_version, $operator_key_id,
            $site_payload_encrypted;
    my $master_iv = random_bytes(12);
    my $master_payload_encrypted = _encrypt_gcm($master_payload, $args{master_key}, $master_iv);

    my $first_char = substr $args{id_str}, 0, 1;
    my $identity_type = ($first_char eq 'F' || $first_char eq 'B') ? UID2::Client::XS::IdentityType::PHONE : UID2::Client::XS::IdentityType::EMAIL;
    my $identity_scope_and_type = (($args{identity_scope} << 4) | ($identity_type << 2) | 3);
    my $version = $args{token_version};
    my $token = pack 'C C a*', $identity_scope_and_type, $version, $master_payload_encrypted;
    my $encode = $version == UID2::Client::XS::AdvertisingTokenVersion::V4 ? \&encode_b64u : \&encode_b64;
    $encode->($token);
}

sub encrypt_data_v2 {
    my ($data, $args) = @_;
    my $iv = random_bytes(16);
    my $payload_type = 128;
    my $version = 1;
    my $now = $args->{now} // UID2::Client::XS::Timestamp->now;
    my $payload = pack 'C C q> N! a*',
            $payload_type, $version, $now->get_epoch_milli,
            $args->{site_id}, _encrypt_cbc($data, $args->{key}, $iv);
    +{
        is_success => 1,
        status => UID2::Client::XS::EncryptionStatus::SUCCESS,
        encrypted_data => encode_b64($payload),
    };
}

sub _encrypt_cbc {
    my ($data, $key, $iv) = @_;
    my $cipher = Crypt::Mode::CBC->new('AES');
    pack 'N! a16 a*', $key->{id}, $iv, $cipher->encrypt($data, $key->{secret}, $iv);
}

sub _encrypt_gcm {
    my ($data, $key, $iv) = @_;
    my $ae = Crypt::AuthEnc::GCM->new('AES', $key->{secret}, $iv);
    my $ciphertext = $ae->encrypt_add($data);
    $ciphertext .= $ae->encrypt_done();
    pack 'N! a12 a*', $key->{id}, $iv, $ciphertext;
}

sub key_set_to_json {
    my @keys = @_;
    encode_json({ body => [
        map {
            my $key = $_;
            +{
                (map { $_ => $key->{$_} } qw(id site_id)),
                (map { $_ => $key->{$_}->get_epoch_second } qw(created activates expires)),
                secret => encode_b64($key->{secret}),
            }
        } @keys
    ]});
}

1;
__END__
