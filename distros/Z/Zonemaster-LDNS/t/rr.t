use v5.16;

use Test::More;
use Test::Fatal qw(exception lives_ok);
use Devel::Peek;
use MIME::Base32 qw(encode_base32hex);
use MIME::Base64;
use Test::Differences;

BEGIN { use_ok( 'Zonemaster::LDNS' ) }

# The following tests use packets that are saved in a base64-encoded form. In
# order to save a packet in Base64 while showing its presentation format, just
# run the following script:
#
# $ perl -MZonemaster::LDNS -MMIME::Base64
# my $p = Zonemaster::LDNS->new("86.54.11.100")->query("iis.se", "SOA");
# say $p->string();
# say encode_base64($p->wireformat());
# ^D

subtest 'rdf' => sub {
    # The packet below has the following equivalent presentation format:
    #
    # ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 19192
    # ;; flags: qr rd ra ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    # ;; QUESTION SECTION:
    # ;; iis.se.      IN      SOA
    #
    # ;; ANSWER SECTION:
    # iis.se. 3600    IN      SOA     nsa.dnsnowhois.stagede.net. hostmaster.nic.se. (
    #                                 1770736690 ; serial
    #                                 14400      ; refresh (4 hours)
    #                                 3600       ; retry (1 hour)
    #                                 2592000    ; expire (4 weeks 2 days)
    #                                 480        ; minimum (8 minutes)
    #                                 )
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
SviBgAABAAEAAAAAA2lpcwJzZQAABgABwAwABgABAAAOEABBA25zYQpkbnNub3dob2lzB3N0YWdl
ZGUDbmV0AApob3N0bWFzdGVyA25pY8AQaYtMMgAAOEAAAA4QACeNAAAAAeA=
DATA

    foreach my $rr ( $p->answer ) {
        is( $rr->rd_count, 7 );
        foreach my $n (0..($rr->rd_count-1)) {
            ok(length($rr->rdf($n)) >= 4);
        }
        like( exception { $rr->rdf(7) }, qr/Trying to fetch nonexistent RDATA at position/, 'died on overflow');
    }
};

subtest 'SOA' => sub {
    # The packet below has the following equivalent presentation format:
    #
    # ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 19192
    # ;; flags: qr rd ra ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    # ;; QUESTION SECTION:
    # ;; iis.se.      IN      SOA
    #
    # ;; ANSWER SECTION:
    # iis.se. 3600    IN      SOA     nsa.dnsnowhois.stagede.net. hostmaster.nic.se. (
    #                                 1770736690 ; serial
    #                                 14400      ; refresh (4 hours)
    #                                 3600       ; retry (1 hour)
    #                                 2592000    ; expire (4 weeks 2 days)
    #                                 480        ; minimum (8 minutes)
    #                                 )
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
SviBgAABAAEAAAAAA2lpcwJzZQAABgABwAwABgABAAAOEABBA25zYQpkbnNub3dob2lzB3N0YWdl
ZGUDbmV0AApob3N0bWFzdGVyA25pY8AQaYtMMgAAOEAAAA4QACeNAAAAAeA=
DATA

    foreach my $rr ( $p->answer ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::SOA' );
        is( lc($rr->mname), 'nsa.dnsnowhois.stagede.net.' );
        is( lc($rr->rname), 'hostmaster.nic.se.' );
        is( $rr->serial,  1770736690, 'serial' );
        is( $rr->refresh, 14400,   'refresh' );
        is( $rr->retry,   3600,    'retry' );
        is( $rr->expire,  2592000, 'expire' );
        is( $rr->minimum, 480,     'minimum' );
    }
};

subtest 'A' => sub {
    # The packet below has the following equivalent presentation format:
    #
    # ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 10728
    # ;; flags: qr rd ra ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    # ;; QUESTION SECTION:
    # ;; a.ns.se.     IN      A
    #
    # ;; ANSWER SECTION:
    # a.ns.se.        86400   IN      A       192.36.144.107
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
KeiBgAABAAEAAAAAAWECbnMCc2UAAAEAAcAMAAEAAQABUYAABMAkkGs
DATA

    foreach my $rr ( $p->answer ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::A' );
        is( $rr->address, '192.36.144.107', 'expected address string' );
        is( $rr->type, 'A' );
        is( length($rr->rdf(0)), 4 );
    }
};

subtest 'AAAA' => sub {
    # The packet below has the following equivalent presentation format:
    #
    # ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 35420
    # ;; flags: qr rd ra ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    # ;; QUESTION SECTION:
    # ;; a.ns.se.     IN      AAAA
    #
    # ;; ANSWER SECTION:
    # a.ns.se.        86400   IN      AAAA    2a01:3f0:0:301::53
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
ilyBgAABAAEAAAAAAWECbnMCc2UAABwAAcAMABwAAQABUYAAECoBA/AAAAMBAAAAAAAAAFM=
DATA

    foreach my $rr ( $p->answer ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::AAAA' );
        is( $rr->address, '2a01:3f0:0:301::53', 'expected address string' );
        is( length($rr->rdf(0)), 16 );
    }
};

subtest 'TXT' => sub {
    my @data = (
        q{txt.test. 3600 IN TXT "Handling TXT RRs can be challenging"},
        q{txt.test. 3600 IN TXT "because " "the data can " "be spl" "it up like " "this!"}
    );
    my @rrs = map { Zonemaster::LDNS::RR->new($_) } @data;

    foreach my $rr ( @rrs ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::TXT' );
    }

    is( $rrs[0]->txtdata(), q{Handling TXT RRs can be challenging} );
    is( $rrs[1]->txtdata(), q{because the data can be split up like this!} );
};

subtest 'DNSKEY' => sub {
    subtest 'Good RR' => sub {
        my @data = (
            q{dnskey.test. 0 IN DNSKEY 257 3 8 BleFgAABAAEAAAAADW5sYWdyaWN1bHR1cmUCbmwAAAEAAcAMADAAAQAAAAAABAEBAwg=},
        );
        my @rrs = map { Zonemaster::LDNS::RR->new($_) } @data;

        foreach my $rr ( @rrs ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::DNSKEY' );
        }

        is( $rrs[0]->flags(),        q{257} );
        is( $rrs[0]->protocol(),     q{3} );
        is( $rrs[0]->algorithm(),    q{8} );
        ok( $rrs[0]->keydata() );
        is( $rrs[0]->hexkeydata(),   q{BleFgAABAAEAAAAADW5sYWdyaWN1bHR1cmUCbmwAAAEAAcAMADAAAQAAAAAABAEBAwg=} );
        is( $rrs[0]->keytag(),       q{27018} );
        is( $rrs[0]->ds('sha256'),   Zonemaster::LDNS::RR->new(q{dnskey.test. 0 IN DS 27018 8 2 cd9b8881a72400a89b0f5ec4b096b07469aa3b316e870291d9e4e0f30f7dd4ed} ));
        is( $rrs[0]->keysize(),      q{344} );
    };

    subtest 'Empty RDATA' => sub {
        my $data = decode_base64( "BleFgAABAAEAAAAADW5sYWdyaWN1bHR1cmUCbmwAAAEAAcAMADAAAQAAAAAABAEBAwg=");
        my $p = Zonemaster::LDNS::Packet->new_from_wireformat( $data );
        my ( $rr, @extra ) = $p->answer_unfiltered;
        eq_or_diff \@extra, [], "no extra RRs found";
        if ( !defined $rr ) {
            BAIL_OUT( "no RR found" );
        }
        is $rr->keydata, "", "we're able to extract the public key field even when it's empty";
        is $rr->hexkeydata, undef, "hexkeydata() returns undef when the public key field is empty";
        is $rr->keysize, -1, "insufficient data to calculate key size is reported as -1";

        my ( @rrs ) = $p->answer;
        eq_or_diff \@rrs, [], "DNSKEY record with empty public key is filtered out by answer()";
    };
};

subtest 'CDNSKEY' => sub {
    subtest 'Good RR' => sub {
        my @data = (
            q{cdnskey.test. 0 IN CDNSKEY 257 3 8 BleFgAABAAEAAAAADW5sYWdyaWN1bHR1cmUCbmwAAAEAAcAMADAAAQAAAAAABAEBAwg=},
        );
        my @rrs = map { Zonemaster::LDNS::RR->new($_) } @data;

        foreach my $rr ( @rrs ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::CDNSKEY' );
        }

        is( $rrs[0]->flags(),        q{257} );
        is( $rrs[0]->protocol(),     q{3} );
        is( $rrs[0]->algorithm(),    q{8} );
        ok( $rrs[0]->keydata() );
        is( $rrs[0]->hexkeydata(),   q{BleFgAABAAEAAAAADW5sYWdyaWN1bHR1cmUCbmwAAAEAAcAMADAAAQAAAAAABAEBAwg=} );
        is( $rrs[0]->keytag(),       q{0} );  # RR type not supported by LDNS
        is( $rrs[0]->ds('sha256'),   undef ); # RR type not supported by LDNS
        is( $rrs[0]->keysize(),      q{344} );
    };

    subtest 'Empty RDATA' => sub {
        my $data = decode_base64( "BleFgAABAAEAAAAADW5sYWdyaWN1bHR1cmUCbmwAAAEAAcAMADAAAQAAAAAABAEBAwg=");
        my $p = Zonemaster::LDNS::Packet->new_from_wireformat( $data );
        my ( $rr, @extra ) = $p->answer_unfiltered;
        eq_or_diff \@extra, [], "no extra RRs found";
        if ( !defined $rr ) {
            BAIL_OUT( "no RR found" );
        }
        is $rr->keydata, "", "we're able to extract the public key field even when it's empty";
        is $rr->hexkeydata, undef, "hexkeydata() returns undef when the public key field is empty";
        is $rr->keysize, -1, "insufficient data to calculate key size is reported as -1";

        my ( @rrs ) = $p->answer;
        eq_or_diff \@rrs, [], "CDNSKEY record with empty public key is filtered out by answer()";
    };
};


subtest 'RRSIG' => sub {
    # The packet below has the following equivalent presentation format.
    # Note however that this was obtained by querying 192.36.144.107 directly
    # instead of going through a public resolver.
    #
    # ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 39105
    # ;; flags: qr aa rd; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 1
    # ;; WARNING: recursion requested but not available
    #
    # ;; OPT PSEUDOSECTION:
    # ; EDNS: version: 0, flags:; udp: 1232
    # ;; QUESTION SECTION:
    # ;se.                    IN RRSIG
    #
    # ;; ANSWER SECTION:
    # se.                     172800 IN RRSIG SOA 8 1 172800 (
    #                                 20260226065448 20260212052448 65293 se.
    #                                 [omitted] )
    # se.                     172800 IN RRSIG NS 8 1 172800 (
    #                                 20260225210943 20260211193943 65293 se.
    #                                 [omitted] )
    # se.                     172800 IN RRSIG TXT 8 1 172800 (
    #                                 20260226065448 20260212052448 65293 se.
    #                                 [omitted] )
    # se.                     7200 IN RRSIG NSEC 8 1 7200 (
    #                                 20260225210943 20260211193943 65293 se.
    #                                 [omitted] )
    # se.                     3600 IN RRSIG DNSKEY 8 1 3600 (
    #                                 20260225210943 20260211193943 59407 se.
    #                                 [omitted] )
    # se.                     172800 IN RRSIG ZONEMD 8 1 172800 (
    #                                 20260226065448 20260212052448 65293 se.
    #                                 [omitted] )

    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
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
AAAAAA==
DATA

    foreach my $rr ( $p->answer ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::RRSIG' );
        is( $rr->signer, 'se.' );
        is( $rr->labels, 1 );
        if ( $rr->typecovered eq 'DNSKEY' ) {
            ok( $rr->keytag == 59407 );
        }
    }
};

subtest 'NSEC' => sub {
    # The packet below has the following equivalent presentation format.
    # Note however that this was obtained by querying 192.36.144.107 directly
    # instead of going through a public resolver.
    #
    # ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 54748
    # ;; flags: qr aa rd ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    # ;; QUESTION SECTION:
    # ;; se.  IN      NSEC
    #
    # ;; ANSWER SECTION:
    # se.     7200    IN      NSEC    0.se. NS SOA TXT RRSIG NSEC DNSKEY ZONEMD

    my $p = Zonemaster::LDNS::Packet->new_from_wireformat(decode_base64(<<DATA));
1dyFAAABAAEAAAAAAnNlAAAvAAHADAAvAAEAABwgABABMAJzZQAACCIAgAAAA4AB
DATA

    foreach my $rr ( $p->answer ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::NSEC' );
        ok( $rr->typehref->{TXT} );
        ok( !$rr->typehref->{MX} );
        ok( $rr->typehref->{TXT} );
        is( $rr->typelist, 'NS SOA TXT RRSIG NSEC DNSKEY ZONEMD ' );
    }
};

subtest 'From string' => sub {
    my $made = Zonemaster::LDNS::RR->new_from_string( 'nic.se IN NS a.ns.se' );
    isa_ok( $made, 'Zonemaster::LDNS::RR::NS' );
    my $made2 = Zonemaster::LDNS::RR->new_from_string( 'nic.se IN NS a.ns.se' );
    is( $made->compare( $made2 ), 0, 'direct comparison works' );
    my $made3 = Zonemaster::LDNS::RR->new_from_string( 'mic.se IN NS a.ns.se' );
    my $made4 = Zonemaster::LDNS::RR->new_from_string( 'oic.se IN NS a.ns.se' );
    is( $made->compare( $made3 ), 1,  'direct comparison works' );
    is( $made->compare( $made4 ), -1, 'direct comparison works' );
    is( $made eq $made2,          1,  'indirect comparison works' );
    is( $made <=> $made3,         1,  'indirect comparison works' );
    is( $made cmp $made4,         -1, 'indirect comparison works' );

    is( "$made", "nic.se.	3600	IN	NS	a.ns.se." );
};

subtest 'DS' => sub {
    subtest 'Good RR' => sub {
        my @data = (
            q{nic.se 3600 IN DS 22643 13 2 aa0b38f6755c2777992a74935d50a2a3480effef1a60bf8643d12c307465c9da},
        );
        my @rrs = map { Zonemaster::LDNS::RR->new($_) } @data;

        foreach my $rr ( @rrs ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::DS' );
        }

        my $key = Zonemaster::LDNS::RR->new( 'nic.se IN DNSKEY 257 3 13 lkpZSlU70pd1LHrXqZttOAYKmX046YqYQg1aQJsv1y0xKr+qJS+3Ue1tM5VCYPU3lKuzq93nz0Lm/AV9jeoumQ==' );
        my $other = Zonemaster::LDNS::RR->new( 'nic.se IN NS a.ns.se' );

        is( $rrs[0]->keytag(),       q{22643} );
        is( $rrs[0]->algorithm(),    q{13} );
        is( $rrs[0]->digtype(),      q{2} );
        ok( $rrs[0]->digest() );
        is( $rrs[0]->hexdigest(),    q{aa0b38f6755c2777992a74935d50a2a3480effef1a60bf8643d12c307465c9da} );
        ok( $rrs[0]->verify( $key ) );
        ok( !$rrs[0]->verify( $other ) );
    };
};

subtest 'CDS' => sub {
    subtest 'Good RR' => sub {
        my @data = (
            q{nic.se 3600 IN CDS 22643 13 2 aa0b38f6755c2777992a74935d50a2a3480effef1a60bf8643d12c307465c9da},
        );
        my @rrs = map { Zonemaster::LDNS::RR->new($_) } @data;

        foreach my $rr ( @rrs ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::CDS' );
        }

        my $key = Zonemaster::LDNS::RR->new( 'nic.se IN CDNSKEY 257 3 13 lkpZSlU70pd1LHrXqZttOAYKmX046YqYQg1aQJsv1y0xKr+qJS+3Ue1tM5VCYPU3lKuzq93nz0Lm/AV9jeoumQ==' );
        my $other = Zonemaster::LDNS::RR->new( 'nic.se IN NS a.ns.se' );

        is( $rrs[0]->keytag(),       q{22643} );
        is( $rrs[0]->algorithm(),    q{13} );
        is( $rrs[0]->digtype(),      q{2} );
        ok( $rrs[0]->digest() );
        is( $rrs[0]->hexdigest(),    q{aa0b38f6755c2777992a74935d50a2a3480effef1a60bf8643d12c307465c9da} );
        ok( !$rrs[0]->verify( $key ) ); # RR type not supported by LDNS
        ok( !$rrs[0]->verify( $other ) );
    };
};

subtest 'NSEC3 without salt' => sub {
    my $name = 'com';
    my $nsec3 = Zonemaster::LDNS::RR->new_from_string(
        'VD0J8N54V788IUBJL9CN5MUD416BS5I6.com. 86400 IN NSEC3 1 1 0 - VD0N3HDL5MG940MOUBCF5MNLKGDT9RFT NS DS RRSIG' );
    isa_ok( $nsec3, 'Zonemaster::LDNS::RR::NSEC3' );
    is( $nsec3->algorithm, 1 );
    is( $nsec3->flags,     1 );
    ok( $nsec3->optout );
    is( $nsec3->iterations,                  0 );
    is( $nsec3->salt,                        '' );
    is( encode_base32hex( $nsec3->next_owner ), "VD0N3HDL5MG940MOUBCF5MNLKGDT9RFT" );
    is( $nsec3->typelist,                    'NS DS RRSIG ' );
    eq_or_diff( $nsec3->hash_name( $name ), 'ck0pojmg874ljref7efn8430qvit8bsm' );

    is_deeply( [ sort keys %{ $nsec3->typehref } ], [qw(DS NS RRSIG)] );
};

subtest 'NSEC3 with salt' => sub {
    my $name = 'bad-values.dnssec03.xa';
    my $nsec3 = Zonemaster::LDNS::RR->new_from_string(
        'BP7OICBR09FICEULBF46U8DMJ1J1V8R3.bad-values.dnssec03.xa. 900 IN NSEC3 1 1 3 8104 c91qe244nd0q5qh3jln35a809mik8d39 A NS SOA MX TXT RRSIG DNSKEY NSEC3PARAM' );
    isa_ok( $nsec3, 'Zonemaster::LDNS::RR::NSEC3' );
    is( $nsec3->algorithm, 1 );
    is( $nsec3->flags,     1 );
    ok( $nsec3->optout );
    is( $nsec3->iterations,                  3 );
    is( unpack('H*', $nsec3->salt),          '8104' );
    is( encode_base32hex( $nsec3->next_owner ), "C91QE244ND0Q5QH3JLN35A809MIK8D39" );
    is( $nsec3->typelist,                    'A NS SOA MX TXT RRSIG DNSKEY NSEC3PARAM ' );
    eq_or_diff( $nsec3->hash_name( $name ), 'u6sj7nlrc80gcqem0ip18mji3vk60djt' );

    is_deeply( [ sort keys %{ $nsec3->typehref } ], [qw(A DNSKEY MX NS NSEC3PARAM RRSIG SOA TXT)] );
};

subtest 'NSEC3 with unknown algorithm' => sub {
    my $name = 'nsec3-mismatches-apex-1.dnssec10.xa.';
    my $nsec3 = Zonemaster::LDNS::RR->new_from_string(
        'G4CPF6T01H8B5U5O996K8HI4OTEE12AA.nsec3-mismatches-apex-1.dnssec10.xa. 86400 IN NSEC3 3 0 0 - UP848IGD2MT1JGD0ISJEB6LAS1DCB11R NS SOA RRSIG DNSKEY NSEC3PARAM TYPE65534' );
    isa_ok( $nsec3, 'Zonemaster::LDNS::RR::NSEC3' );
    is( $nsec3->algorithm, 3 );
    is( $nsec3->flags,     0 );
    is( $nsec3->optout,    '' );
    is( $nsec3->iterations,                  0 );
    is( unpack('H*', $nsec3->salt),          '' );
    is( encode_base32hex( $nsec3->next_owner ), "UP848IGD2MT1JGD0ISJEB6LAS1DCB11R" );
    is( $nsec3->typelist,                    'NS SOA RRSIG DNSKEY NSEC3PARAM TYPE65534 ' );
    eq_or_diff( $nsec3->hash_name( $name ), undef );

    is_deeply( [ sort keys %{ $nsec3->typehref } ], [qw(DNSKEY NS NSEC3PARAM RRSIG SOA TYPE65534)] );
};

subtest 'NSEC3PARAM without salt and non-zero flags' => sub {
    my $name = 'empty-nsec3param.example';
    my $nsec3param = Zonemaster::LDNS::RR->new_from_string(
        'empty-nsec3param.example. 86400 IN NSEC3PARAM 1 165 0 -' );
    isa_ok( $nsec3param, 'Zonemaster::LDNS::RR::NSEC3PARAM' );
    is( $nsec3param->algorithm,  1 );
    is( $nsec3param->flags,      0xA5 );
    is( $nsec3param->iterations, 0 );
    is( $nsec3param->salt,       '', 'Salt');
    is( lc($nsec3param->owner),  'empty-nsec3param.example.' );
    eq_or_diff( $nsec3param->hash_name( $name ), 'l73q01jb3imjq6krmm5h00evfsdpmbvl' );
};

subtest 'NSEC3PARAM with salt' => sub {
    my $name = 'whitehouse.gov.';
    my $nsec3param = Zonemaster::LDNS::RR->new_from_string( 'whitehouse.gov.		3600	IN	NSEC3PARAM 1 0 2 B2C19AB526819347' );
    isa_ok( $nsec3param, 'Zonemaster::LDNS::RR::NSEC3PARAM' );
    is( $nsec3param->algorithm,  1 );
    is( $nsec3param->flags,      0 );
    is( $nsec3param->iterations, 2, "Iterations" );
    is( uc(unpack( 'H*', $nsec3param->salt )), 'B2C19AB526819347', "Salt" );
    is( lc($nsec3param->owner), 'whitehouse.gov.' );
    eq_or_diff( $nsec3param->hash_name( $name ), '2mo42ugf34bnruvljv91vv9vqd4kckda' );
};

subtest 'NSEC3PARAM with unknown algorithm' => sub {
    my $name = 'GOOD-NSEC3-1.dnssec10.xa';
    my $nsec3param = Zonemaster::LDNS::RR->new_from_string( 'good-nsec3-1.dnssec10.xa. 0     IN      NSEC3PARAM 3 0 0 -' );
    isa_ok( $nsec3param, 'Zonemaster::LDNS::RR::NSEC3PARAM' );
    is( $nsec3param->algorithm, 3 );
    is( $nsec3param->flags,     0 );
    is( $nsec3param->iterations,                  0 );
    is( unpack('H*', $nsec3param->salt),          '' );
    is( lc($nsec3param->owner), 'good-nsec3-1.dnssec10.xa.' );
    eq_or_diff( $nsec3param->hash_name( $name ), undef );
};

subtest 'SIG' => sub {
    my $sig = Zonemaster::LDNS::RR->new_from_string('sig.example. 3600 IN SIG A 1 2 3600 19970102030405 19961211100908 2143 sig.example. AIYADP8d3zYNyQwW2EM4wXVFdslEJcUx/fxkfBeH1El4ixPFhpfHFElxbvKoWmvjDTCmfiYy2X+8XpFjwICHc398kzWsTMKlxovpz2FnCTM=');
    isa_ok( $sig, 'Zonemaster::LDNS::RR::SIG' );
    can_ok( 'Zonemaster::LDNS::RR::SIG', qw(check_rd_count) );
    is( $sig->check_rd_count(), '1' );
};

subtest 'SRV' => sub {
    my $srv = Zonemaster::LDNS::RR->new( '_nicname._tcp.se.	172800	IN	SRV	0 0 43 whois.nic-se.se.' );
    is( $srv->type, 'SRV' );
};

subtest 'SPF' => sub {
    my @data = (
        q{frobbit.se.           1127    IN      SPF     "v=spf1 ip4:85.30.129.185/24 mx:mail.frobbit.se ip6:2a02:80:3ffe::0/64 ~all"},
        q{spf.example.          3600    IN      SPF     "v=spf1 " "ip4:192.0.2.25/24 " "mx:mail.spf.example " "ip6:2001:db8::25/64 -all"}
    );

    my @rr = map { Zonemaster::LDNS::RR->new($_) } @data;
    for my $spf (@rr) {
        isa_ok( $spf, 'Zonemaster::LDNS::RR::SPF' );
    }

    is( $rr[0]->spfdata(), 'v=spf1 ip4:85.30.129.185/24 mx:mail.frobbit.se ip6:2a02:80:3ffe::0/64 ~all' );
    is( $rr[1]->spfdata(), 'v=spf1 ip4:192.0.2.25/24 mx:mail.spf.example ip6:2001:db8::25/64 -all' );

};

subtest 'DNAME' => sub {
    my $rr = Zonemaster::LDNS::RR->new( 'examplë.fake 3600  IN  DNAME example.fake' );
    isa_ok( $rr, 'Zonemaster::LDNS::RR::DNAME' );
    is($rr->dname(), 'example.fake.');
};

subtest 'SVCB' => sub {
    my $rr = Zonemaster::LDNS::RR->new( q{_8443._foo.api.example.com. 7200 IN SVCB 0 svc4.example.net.} );
    isa_ok( $rr, 'Zonemaster::LDNS::RR::SVCB' );
    lives_ok { $rr->check_rd_count() } '$rr->check_rd_count() does not crash';
};

subtest 'HTTPS' => sub {
    my $rr = Zonemaster::LDNS::RR->new( q{example.com. 3600 IN HTTPS 0 svc.example.net.} );
    isa_ok( $rr, 'Zonemaster::LDNS::RR::HTTPS' );
    lives_ok { $rr->check_rd_count() } '$rr->check_rd_count() does not crash';
};

subtest 'generic type' => sub {
    my $rr = Zonemaster::LDNS::RR->new( q{type1234.example. 3600 IN TYPE1234 \# 4 ABCDABCD} );
    isa_ok( $rr, 'Zonemaster::LDNS::RR' );
    lives_ok { $rr->check_rd_count() } '$rr->check_rd_count() does not crash';
};

subtest 'croak when given malformed CAA records' => sub {
    my $will_croak = sub {
        # This will croak if LDNS.xs is compiled with -DUSE_ITHREADS
        my $bad_caa = Zonemaster::LDNS::RR->new(
            'bad-caa.example.       3600    IN      CAA     \# 4 C0000202' );
        # This will always croak
        $bad_caa->string();
    };
    like( exception(sub { $will_croak->() }), qr/^Failed to convert RR to string/ );
};

done_testing;
