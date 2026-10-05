use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::Connection;

my @varints = (
    '0',
    '63',
    '64',
    '16383',
    '16384',
    '1073741823',
    '1073741824',
    '4611686018427387903',
);

for my $value (@varints) {
    my $encoded = Unblock::HTTP3::Connection::_encode_http3_varint($value);
    my ($decoded, $length) =
        Unblock::HTTP3::Connection::_decode_http3_varint($encoded, 0);

    is($decoded, $value, "HTTP/3 varint $value round trips");
    is($length, length($encoded), "HTTP/3 varint $value length is reported");
}

for my $reserved (6, 8, 51) {
    like(
        dies {
            Unblock::HTTP3::Connection::_normalize_extension_settings({
                $reserved => 1,
            });
        },
        qr/setting $reserved is reserved for dedicated Unblock::HTTP3 support/,
        "HTTP/3 setting $reserved is reserved for dedicated support",
    );
}

for my $reserved (0, 2, 3, 4, 5) {
    like(
        dies {
            Unblock::HTTP3::Connection::_normalize_extension_settings({
                $reserved => 1,
            });
        },
        qr/setting $reserved is reserved/,
        "HTTP/3 reserved setting $reserved cannot be used as an extension",
    );
}

for my $grease (33, 64, 95) {
    like(
        dies {
            Unblock::HTTP3::Connection::_normalize_extension_settings({
                $grease => 1,
            });
        },
        qr/reserved for greasing/,
        "HTTP/3 GREASE setting $grease cannot be assigned semantics",
    );
}

like(
    dies {
        Unblock::HTTP3::Connection::_normalize_extension_settings({
            4660 => '4611686018427387904',
        });
    },
    qr/exceeds the HTTP\/3 varint maximum/,
    'extension SETTINGS values must fit in an HTTP/3 varint',
);

my $native_payload =
      Unblock::HTTP3::Connection::_encode_http3_varint(1)
    . Unblock::HTTP3::Connection::_encode_http3_varint(4096)
    . Unblock::HTTP3::Connection::_encode_http3_varint(6)
    . Unblock::HTTP3::Connection::_encode_http3_varint(65536);

my $native_wire =
      Unblock::HTTP3::Connection::_encode_http3_varint(0)
    . Unblock::HTTP3::Connection::_encode_http3_varint(4)
    . Unblock::HTTP3::Connection::_encode_http3_varint(length($native_payload))
    . $native_payload;

my ($rewritten, $native_length, $delta) =
    Unblock::HTTP3::Connection::_rewrite_control_settings(
        $native_wire,
        {
            4660 => 7,
            4661 => 11,
        },
    );

is($native_length, length($native_wire),
    'SETTINGS rewrite reports the native byte count');
ok($delta > 0,
    'SETTINGS rewrite adds extension bytes to the control stream');
is(length($rewritten), $native_length + $delta,
    'SETTINGS rewrite reports the wire/native offset delta');

my $inspector = bless {
    peer_settings_parser => {},
}, 'Unblock::HTTP3::Connection';

for my $byte (split //, $rewritten) {
    $inspector->_inspect_peer_settings_bytes(2, $byte);
}

is(
    $inspector->{pending_peer_extension_settings},
    {
        4660 => '7',
        4661 => '11',
    },
    'peer SETTINGS inspector preserves semantic extension SETTINGS',
);

my $grease_payload =
      Unblock::HTTP3::Connection::_encode_http3_varint(33)
    . Unblock::HTTP3::Connection::_encode_http3_varint(99)
    . Unblock::HTTP3::Connection::_encode_http3_varint(4660)
    . Unblock::HTTP3::Connection::_encode_http3_varint(7);

my $grease_wire =
      Unblock::HTTP3::Connection::_encode_http3_varint(0)
    . Unblock::HTTP3::Connection::_encode_http3_varint(4)
    . Unblock::HTTP3::Connection::_encode_http3_varint(length($grease_payload))
    . $grease_payload;

my $grease_inspector = bless {
    peer_settings_parser => {},
}, 'Unblock::HTTP3::Connection';

for my $byte (split //, $grease_wire) {
    $grease_inspector->_inspect_peer_settings_bytes(2, $byte);
}

is(
    $grease_inspector->{pending_peer_extension_settings},
    { 4660 => '7' },
    'peer GREASE SETTINGS are ignored rather than assigned extension meaning',
);

my $ignored = bless {
    peer_settings_parser => {},
}, 'Unblock::HTTP3::Connection';

$ignored->_inspect_peer_settings_bytes(
    2,
    Unblock::HTTP3::Connection::_encode_http3_varint(2),
);

ok(
    !exists $ignored->{pending_peer_extension_settings},
    'non-control unidirectional streams are ignored by SETTINGS inspection',
);

{
    package Local::HTTP3SettingsQUIC;

    sub new {
        return bless {}, shift;
    }

    sub close {
        my ($self, $code) = @_;
        $self->{closed_with} = $code;
        return;
    }
}

for my $case (
    [ 8,  2, 'SETTINGS_ENABLE_CONNECT_PROTOCOL' ],
    [ 51, 2, 'SETTINGS_H3_DATAGRAM' ],
) {
    my ($id, $value, $name) = @$case;
    my $payload =
          Unblock::HTTP3::Connection::_encode_http3_varint($id)
        . Unblock::HTTP3::Connection::_encode_http3_varint($value);
    my $wire =
          Unblock::HTTP3::Connection::_encode_http3_varint(0)
        . Unblock::HTTP3::Connection::_encode_http3_varint(4)
        . Unblock::HTTP3::Connection::_encode_http3_varint(length($payload))
        . $payload;

    my $quic = Local::HTTP3SettingsQUIC->new;
    my $strict = bless {
        peer_settings_parser => {},
        transactions         => {},
        quic                 => $quic,
        failed               => 0,
    }, 'Unblock::HTTP3::Connection';

    $strict->_inspect_peer_settings_bytes(2, $wire);

    ok($strict->failed,
        "$name outside 0 or 1 fails the HTTP/3 connection");
    is($strict->error_code, 0x0109,
        "$name invalid value uses H3_SETTINGS_ERROR");
    is($quic->{closed_with}, 0x0109,
        "$name invalid value closes QUIC with H3_SETTINGS_ERROR");
}

my $fake_quic = Local::HTTP3SettingsQUIC->new;

my $validator = bless {
    transactions                    => {},
    quic                            => $fake_quic,
    failed                          => 0,
    peer_extension_settings         => {},
    peer_settings_received          => 0,
    pending_peer_extension_settings => { 4660 => '99' },
    on_extension_settings           => sub {
        my ($connection, $settings) = @_;
        die "setting 4660 must be 7"
            unless $settings->{4660} eq '7';
    },
}, 'Unblock::HTTP3::Connection';

ok(
    !$validator->_accept_peer_extension_settings,
    'extension SETTINGS validator can reject peer SETTINGS',
);

ok($validator->failed,
    'validator rejection fails the HTTP/3 connection');
is($validator->error_code, 0x0109,
    'validator rejection uses H3_SETTINGS_ERROR');
is($fake_quic->{closed_with}, 0x0109,
    'validator rejection closes QUIC with H3_SETTINGS_ERROR');
like($validator->error, qr/setting 4660 must be 7/,
    'validator rejection preserves useful error text');

done_testing;
