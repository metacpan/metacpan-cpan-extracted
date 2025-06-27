use v5.16;

use Test::More;
use Test::Fatal;
use Devel::Peek;
use MIME::Base32 qw(encode_base32hex);
use MIME::Base64;
use Test::Differences;

BEGIN { use_ok( 'Zonemaster::LDNS' ) }

my $s;
$s = Zonemaster::LDNS->new( '8.8.8.8' ) if $ENV{TEST_WITH_NETWORK};

subtest 'rdf' => sub {
    SKIP: {
        skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

        my $p = $s->query( 'iis.se', 'SOA' );
        plan skip_all => 'No response, cannot test' if not $p;

        foreach my $rr ( $p->answer ) {
            is( $rr->rd_count, 7 );
            foreach my $n (0..($rr->rd_count-1)) {
                ok(length($rr->rdf($n)) >= 4);
            }
            like( exception { $rr->rdf(7) }, qr/Trying to fetch nonexistent RDATA at position/, 'died on overflow');
        }
    }
};

subtest 'SOA' => sub {
    SKIP: {
        skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

        my $p = $s->query( 'iis.se', 'SOA' );
        plan skip_all => 'No response, cannot test' if not $p;

        foreach my $rr ( $p->answer ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::SOA' );
            is( lc($rr->mname), 'ns.nic.se.' );
            is( lc($rr->rname), 'hostmaster.nic.se.' );
            ok( $rr->serial >= 1381471502, 'serial' );
            is( $rr->refresh, 14400,   'refresh' );
            is( $rr->retry,   3600,    'retry' );
            is( $rr->expire,  2592000, 'expire' );
            is( $rr->minimum, 600,     'minimum' );
        }
    }
};

subtest 'A' => sub {
    SKIP: {
        skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

        my $p = $s->query( 'a.ns.se' );
        plan skip_all => 'No response, cannot test' if not $p;

        foreach my $rr ( $p->answer ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::A' );
            is( $rr->address, '192.36.144.107', 'expected address string' );
            is( $rr->type, 'A' );
            is( length($rr->rdf(0)), 4 );
        }
    }
};

subtest 'AAAA' => sub {
    SKIP: {
        skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

        my $p = $s->query( 'a.ns.se', 'AAAA' );
        plan skip_all => 'No response, cannot test' if not $p;

        foreach my $rr ( $p->answer ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::AAAA' );
            is( $rr->address, '2a01:3f0:0:301::53', 'expected address string' );
            is( length($rr->rdf(0)), 16 );
        }
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
    SKIP: {
        skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

        my $se = Zonemaster::LDNS->new( '192.36.144.107' );
        my $pr = $se->query( 'se', 'RRSIG' );
        plan skip_all => 'No response, cannot test' if not $pr;

        foreach my $rr ( $pr->answer ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::RRSIG' );
            is( $rr->signer, 'se.' );
            is( $rr->labels, 1 );
            if ( $rr->typecovered eq 'DNSKEY' ) {
                # .SE KSK should not change very often. 59407 has replaced 59747.
                # Now (February 2022) only 59407 is used.
                ok( $rr->keytag == 59407 );
            }
        }
    }
};

subtest 'NSEC' => sub {
    SKIP: {
        skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

        my $se = Zonemaster::LDNS->new( '192.36.144.107' );
        my $pn = $se->query( 'se', 'NSEC' );
        plan skip_all => 'No response, cannot test' if not $pn;

        foreach my $rr ( $pn->answer ) {
            isa_ok( $rr, 'Zonemaster::LDNS::RR::NSEC' );
            ok( $rr->typehref->{TXT} );
            ok( !$rr->typehref->{MX} );
            ok( $rr->typehref->{TXT} );
            is( $rr->typelist, 'NS SOA TXT RRSIG NSEC DNSKEY ZONEMD ' );
        }
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
