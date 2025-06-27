use Test::More;
use Devel::Peek;
use version;

BEGIN { use_ok( 'Zonemaster::LDNS' ) }

my $lib_v = version->parse(Zonemaster::LDNS::lib_version());
ok( $lib_v >= v1.6.16, 'ldns version at least 1.6.16' );

SKIP: {
    skip 'no network', 59 unless $ENV{TEST_WITH_NETWORK};

    my $s = Zonemaster::LDNS->new( '8.8.8.8' );
    isa_ok( $s, 'Zonemaster::LDNS' );

    my $p2 = $s->query( 'iis.se', 'NS', 'IN' );
    isa_ok( $p2, 'Zonemaster::LDNS::Packet' );
    is( $p2->rcode, 'NOERROR' );
    is( $p2->opcode, 'QUERY', 'expected opcode' );
    my $pround = Zonemaster::LDNS::Packet->new_from_wireformat( $p2->wireformat );
    isa_ok( $pround, 'Zonemaster::LDNS::Packet' );
    is( $pround->opcode, $p2->opcode, 'roundtrip opcode OK' );
    is( $pround->rcode,  $p2->rcode,  'roundtrip rcode OK' );

    ok( $p2->id() > 0, 'packet ID set' );
    ok( $p2->qr(),     'QR bit set' );
    ok( !$p2->aa(),    'AA bit not set' );
    ok( !$p2->tc(),    'TC bit not set' );
    ok( $p2->rd(),     'RD bit set' );
    ok( !$p2->cd(),    'CD bit not set' );
    ok( $p2->ra(),     'RA bit set' );
    ok( !$p2->ad(),    'AD bit not set' );
    ok( !$p2->do(),    'DO bit not set' );

    cmp_ok( $p2->querytime, '>=', 0);
    is( $p2->answerfrom, '8.8.8.8', 'expected answerfrom' );
    $p2->answerfrom( '1.2.3.4' );
    is( $p2->answerfrom, '1.2.3.4', 'setting answerfrom works' );

    ok($p2->timestamp > 0, 'has a timestamp to begin with');
    $p2->timestamp( 4711 );
    is( $p2->timestamp, 4711, 'setting timestamp works' );
    $p2->timestamp( 4711.4711 );
    ok( $p2->timestamp - 4711.4711 < 0.0001, 'setting timestamp works with microseconds too' );

    eval { $s->query( 'nic.se', 'gurksallad', 'CH' ) };
    like( $@, qr/Unknown RR type: gurksallad/ );

    eval { $s->query( 'nic.se', 'SOA', 'gurksallad' ) };
    like( $@, qr/Unknown RR class: gurksallad/ );

    eval { $s->query( 'nic.se', 'soa', 'IN' ) };
    ok( !$@ );

    my @answer = $p2->answer;
    cmp_ok( scalar( @answer ), '<=', 6, 'at most 6 NS records in answer (iis.se)' );
    cmp_ok( scalar( @answer ), '>=', 2, 'at least 2 NS records in answer (iis.se)' );
    my %known_ns = map { $_ => 1 } qw[nsp.dnsnode.net. nsa.dnsnode.net. nsu.dnsnode.net.];
    foreach my $rr ( @answer ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR::NS' );
        is( lc($rr->owner), 'iis.se.', 'expected owner name' );
        ok( $rr->ttl > 0, 'positive TTL (' . $rr->ttl . ')' );
        is( $rr->type,  'NS', 'type is NS' );
        is( $rr->class, 'IN', 'class is IN' );
        ok( $known_ns{ lc($rr->nsdname) }, 'known nsdname (' . $rr->nsdname . ')' );
    }

    my $p = $s->query( 'zonemaster.fr', 'MX' );
    isa_ok( $p, 'Zonemaster::LDNS::Packet' );
    is( $p->rcode, 'NOERROR', 'expected rcode' );

    @answer = sort { $a->preference <=> $b->preference } $p->answer;
    is( $answer[0]->preference, 7, 'expected MX preference 7' );
    is( lc($answer[0]->exchange), 'mx1.nic.fr.', 'known MX exchange mx1.nic.fr' );
    is( $answer[1]->preference, 8, 'expected MX preference 8' );
    is( lc($answer[1]->exchange), 'mx2.nic.fr.', 'known MX exchange mx2.nic.fr' );

    my $lroot = Zonemaster::LDNS->new( '199.7.83.42' );
    my $se = $lroot->query( 'se', 'NS' );

    is( scalar( $se->question ),   1,  'one question' );
    is( scalar( $se->answer ),     0,  'zero answers' );
    my $authority = scalar $se->authority;
    cmp_ok( $authority, '<=', 13, 'at most 13 NS (authority)' );
    cmp_ok( $authority, '>=', 6, 'at least 6 NS (authority)' );
    my $add = scalar( $se->additional );
    cmp_ok( $add, '<=', 26, 'at most 20 additional' );
    cmp_ok( $add, '>=', 8, 'at least 8 additional' );

    my $rr = Zonemaster::LDNS::RR->new_from_string(
        'se. 172800	IN	SOA	catcher-in-the-rye.nic.se. registry-default.nic.se. 2013111305 1800 1800 864000 7200' );
    my $rr2 =
      Zonemaster::LDNS::RR->new( 'se.			172800	IN	TXT	"SE zone update: 2013-11-13 15:08:28 +0000 (EPOCH 1384355308) (auto)"' );
    ok( $se->unique_push( 'answer', $rr ), 'unique_push returns ok' );
    is( $se->answer, 1, 'one record in answer section' );
    ok( !$se->unique_push( 'answer', $rr ), 'unique_push returns false' );
    is( $se->answer, 1, 'still one record in answer section' );
    ok( $se->unique_push( 'ansWer', $rr2 ), 'unique_push returns ok again' );
    is( $se->answer, 2, 'two records in answer section' );
}

my $made = Zonemaster::LDNS::Packet->new( 'foo.com', 'SOA', 'IN' );
isa_ok( $made, 'Zonemaster::LDNS::Packet' );

foreach my $flag (qw[do qr tc aa rd cd ra ad]) {
    ok(!$made->$flag(), uc($flag).' not set');
    $made->$flag(1);
    ok($made->$flag(), uc($flag).' set');
}

is($made->edns_size, 0, 'Initial EDNS0 UDP size is 0');
ok($made->edns_size(4096));
is($made->edns_size, 4096, 'EDNS0 UDP size set to 4096');
ok(!$made->edns_size(2**17), 'Setting to too big did not work'); # Too big

is($made->edns_rcode, 0, 'Extended RCODE is 0');
$made->edns_rcode(1);
is($made->edns_rcode, 1, 'Extended RCODE is 1');

is($made->type, 'answer');

done_testing;
