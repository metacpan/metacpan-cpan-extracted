use strict;
use warnings;
use v5.16;

use utf8;

use open ':std', ':encoding(UTF-8)';

use Encode;
use MIME::Base64;
use Test::Differences;
use Test::Fatal qw(exception lives_ok);
use Test::More;

BEGIN { use_ok( 'Zonemaster::LDNS' ) }

sub test_first_ede {
    my ( $packet, $expected_ede, $expected_extra_text ) = @_;

    my $expected_ede_message = (defined $expected_ede) ?
        'Got expected EDE' : 'Got no EDE';
    my $expected_ede_text_message = (defined $expected_extra_text) ?
        'Got expected extra text' : 'Got no extra text';

    {
        my $ede;
        is(
            exception { $ede = $packet->first_ede() },
            undef,
            'first_ede() method works in scalar context'
        );
        is( $ede, $expected_ede, $expected_ede_message );
    }
    {
        my @array;
        is(
            exception { @array = $packet->first_ede() },
            undef,
            'first_ede() method works in list context'
        );
        # In some scenarios, list context calls can return 0 or 1 item. This
        # is acceptable because missing values in the code that unpacks the
        # following array become undef. As long as we don’t return more than
        # two, it’s fine.
        cmp_ok( scalar @array, '<=', 2 );
        my ( $ede, $extra_text ) = @array;
        is( $ede, $expected_ede, $expected_ede_message );
        is( $extra_text, $expected_extra_text, $expected_ede_text_message );
    }
}

#
# This test packet was obtained by performing the following query:
#
# % dig @ns1.ede-13.extended-dns-errors.com TXT ede-13.extended-dns-errors.com.
#
# It contains an EDE 13 (Cached Error) with the extra text “This EDE was
# intentionally inserted by dnsdist”.
#
subtest 'Packet with EDE + ASCII text' => sub {
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
jCGFAAABAAAAAQABBmVkZS0xMxNleHRlbmRlZC1kbnMtZXJyb3JzA2NvbQAAEAABwAwABgABAAACWA
AnA25zMcAMCmhvc3RtYXN0ZXLADAE1ALUAAFRgAAAOEAAJOoAAAVGAAAApBNAAAAAAAFAACgAY2Jns
Gd/Ahl4BAAAAac0D6x4N9CxTQ07sAA8AMAANVGhpcyBFREUgd2FzIGludGVudGlvbmFsbHkgaW5zZX
J0ZWQgYnkgZG5zZGlzdA==
DATA

    test_first_ede( $p, 13, 'This EDE was intentionally inserted by dnsdist' );
};

#
# This test packet was obtained by performing the following query:
#
# % dig @a.ede.dn5.dk AAAA network-error.nx.ede.dn5.dk
#
# It contains an EDE 13 (Cached Error) with the extra text “🔥🔥🔥”.
#
subtest 'Packet with EDE + UTF-8 text' => sub {
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
6D+FAwABAAAAAAABDW5ldHdvcmstZXJyb3ICbngDZWRlA2RuNQJkawAAHAABAAApBNAAAAAAABIADw
AOABfwn5Sl8J+UpfCflKU=
DATA

    test_first_ede( $p, 23, '🔥🔥🔥' );
};

#
# This is a synthetic test packet.
#
# It contains an EDE 0 (Other) with some extra text which is not
# a valid UTF-8 sequence.
#
# Although RFC 8914 specifies that the EXTRA-TEXT be UTF-8-encoded,
# we should accept byte sequences that are invalid.
#
subtest 'Packet with EDE + invalid UTF-8 text' => sub {
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(
        pack( 'H*', (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx) ) );
000084020001000000000001     # Header: QR AA, SERVFAIL
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 000e   # Additional section: OPT pseudo-RR
000f 000a 0000               # EDNS option 15 (EDE), length and code 0
48 65 6c 70 aa 6d 65 bb      # Extra text
DATA
    test_first_ede( $p, 0, "Help\xAAme\xBB" );
};

#
# This test packet was obtained by performing the following query:
#
# % dig +nord +nocookie @aphrodite.x0r.fr SOA blah.
#
# It contains an EDE 20 (Not Authoritative) with no extra text.
#

subtest 'Test packet with plain EDE' => sub {
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
s5yABQABAAAAAAABBGJsYWgAAAYAAQAAKRAAAAAAAAAGAA8AAgAU
DATA

    test_first_ede( $p, 20, undef );
};

#
# Test setting an EDE in an existing packet.
#

subtest 'setting plain EDE in packet' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );
    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    test_first_ede( $p, undef, undef );

    is(
        exception { $p->first_ede(1) },
        undef,
        'Setting plain EDE doesn’t crash'
    );
    test_first_ede( $p, 1, undef );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 0006   # Additional section: OPT pseudo-RR
000f 0002 0001               # EDNS option 15 (EDE), length and code 1
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet contains only one instance of EDE'
    );
};

subtest 'setting EDE multiple times only keeps one instance of EDE' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );
    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    is(
        exception { $p->first_ede($_) for 1..4 },
        undef,
        'Setting plain EDE 4 times in a row doesn’t crash'
    );
    test_first_ede( $p, 4, undef );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 0006   # Additional section: OPT pseudo-RR
000f 0002 0004               # EDNS option 15 (EDE), length and code 4
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet contains only one instance of EDE'
    );
};

subtest 'setting EDE with extra text' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );
    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    is(
        exception { $p->first_ede(13, 'AXFR failed: REFUSED') },
        undef,
        'Setting EDE with text doesn’t crash'
    );
    test_first_ede( $p, 13, 'AXFR failed: REFUSED' );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 001a   # Additional section: OPT pseudo-RR
000f 0016                    # EDNS option 15 (EDE) and length
000d 41584652206661696c65643a2052454655534544  # EDE code 13 and text
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet contains only one instance of EDE'
    );
};

subtest 'setting EDE with UTF-8 Latin text' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );
    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    my $backup = 'français';
    my $extra_text = 'français';

    is(
        exception { $p->first_ede(29, $extra_text) },
        undef,
        'Setting EDE with UTF-8 text doesn’t crash'
    );
    test_first_ede( $p, 29, $backup );

    is( $extra_text, $backup, 'Setting EDE has no ill side-effects on input variable' );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 000f   # Additional section: OPT pseudo-RR
000f 000b                    # EDNS option 15 (EDE) and length
001d 6672616ec3a7616973      # EDE code 29 and text
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet contains only one instance of EDE'
    );
};

subtest 'setting EDE with UTF-8 emoji text' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );
    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    my $backup = '🐈';
    my $extra_text = '🐈';

    is(
        exception { $p->first_ede(29, $extra_text) },
        undef,
        'Setting EDE with UTF-8 text doesn’t crash'
    );
    test_first_ede( $p, 29, $backup );

    is( $extra_text, $backup, 'Setting EDE has no ill side-effects on input variable' );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 000a   # Additional section: OPT pseudo-RR
000f 0006                    # EDNS option 15 (EDE) and length
001d f09f9088                # EDE code 29 and cat emoji (U+1F408)
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet contains only one instance of EDE'
    );
};

subtest 'setting EDE with null bytes in it' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );
    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    my $extra_text = "Messing\0with\0you\0";

    is(
        exception { $p->first_ede(65530, $extra_text) },
        undef,
        'Setting EDE with embedded null bytes doesn’t crash'
    );
    test_first_ede( $p, 65530, $extra_text );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 0017   # Additional section: OPT pseudo-RR
000f 0013                    # EDNS option 15 (EDE) and length
fffa 4d657373696e67 00 77697468 00 796f75 00 # EDE code and string
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet’s wireformat is correct'
    );
};

subtest 'setting EDE with invalid UTF-8 sequence in extra-text' => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'test' );

    $p->qr(1);
    $p->aa(1);
    $p->opcode('QUERY');
    $p->rcode('REFUSED');

    my $extra_text = Encode::encode('iso-8859-1', "\x80\x81\x82\x83");

    is(
        exception { $p->first_ede(65530, $extra_text) },
        undef,
        'Setting EDE with embedded null bytes doesn’t crash'
    );
    test_first_ede( $p, 65530, $extra_text );

    my $expected_wireformat = (<<DATA =~ s/ \s | \# [^\n]* \n //mgrx);
000084050001000000000001     # Header
04746573740000010001         # Question section: test./IN/A
00 0029 0000 00000000 000a   # Additional section: OPT pseudo-RR
000f 0006                    # EDNS option 15 (EDE) and length
fffa 80818283                # EDE code and string
DATA

    is(
        unpack( 'H*', $p->wireformat() ),
        $expected_wireformat,
        'Packet’s wireformat is correct'
    );
};

done_testing;
