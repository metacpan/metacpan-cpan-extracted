use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Zonemaster::LDNS') }


=head2 wireformat_ok( string )

Test that the given resource record stays the same when serialized and deserialized
through wireformat using Zonemaster::LDNS::Packet::wireformat() and
Zonemaster::LDNS::Packet::new_from_wireformat().

The initial resource record is constructed from the given B<string> using
Zonemaster::LDNS::RR::new().

=cut

sub wireformat_ok {
    my $string = shift;

    my $rr1 = Zonemaster::LDNS::RR->new($string);

    my $packet1 = Zonemaster::LDNS::Packet->new('example.com.');
    $packet1->unique_push( 'answer', $rr1 );

    my $wireformat = $packet1->wireformat();

    my $packet2 = Zonemaster::LDNS::Packet->new_from_wireformat($wireformat);
    my $rr2     = ( $packet2->answer )[0];

    cmp_ok $rr1, 'eq', $rr2, "Wireformat round-trip for: " . $string;
    return;
}

# Test wireformat round trips for different record types
wireformat_ok('example.com.            A          192.0.2.1');
wireformat_ok('example.com.            AAAA       2001:db8::3');
wireformat_ok('abc.example.com.        AFSDB      1 afs-server.example.com.');
wireformat_ok('example.com.            CAA        0 issue "ca.example.net; account=123456"');
wireformat_ok('smith                   CERT       PGP 0 0 aNvv4w==');
wireformat_ok('example.com.            CNAME      joe.example.com.');
wireformat_ok('example.com.            DNAME      example.net.');
wireformat_ok('example.com.            DNSKEY     256 3 5 742iU/TpPSEDhm2SNKLijfUppn1U aNvv4w==');
wireformat_ok('example.                DS         12345 3 1 123456789abcdef67890123456789abcdef67890');
wireformat_ok('example.com.            HINFO      PC-Intel-700mhz "Redhat Linux 7.1"');
wireformat_ok('geo.example.com.        LOC        42 21 43.528 N 71 05 06.284 W 12m');
wireformat_ok('example.com.            MX         10 mail.example.com.');
wireformat_ok('example.com.            NAPTR      100 10 u sip+E2U !^.*$!sip:info@info.example.test!i .');
wireformat_ok('example.com.            NS         ns1.example.com.');
wireformat_ok('example.com.            NSEC       aaa.example.com. NS SOA RRSIG NSEC DNSKEY');
wireformat_ok('example.                NSEC3      1 1 12 aabbccdd 2vptu5timamqttgl4luu9kg21e0aor3s A RRSIG');
wireformat_ok('example.com.            NSEC3PARAM 1 0 1 B606B568');
wireformat_ok('2.2.0.192.in-addr.arpa. PTR        www.example.com.');
wireformat_ok('my.example.com.         RP         who.example.com txtrec.example.com');
wireformat_ok('www.example.com.        RRSIG      AAAA 5 3 60 20171006161502 20170926161502 25665 example.com. khOgZGrdkaggUfmZbOFjZLXWZsA8 u+Y=');
wireformat_ok('example.com.            SOA        ns1.example.com. hostmaster.example.com. 2003080800 172800 900 1209600 3600');
wireformat_ok('example.com.            SPF        10 5 80 hostname.example.com');
wireformat_ok('_http._tcp.example.com. SRV        0 5 80 www.example.com.');
wireformat_ok('random.example.com.     SSHFP      1 1 23D3C516AAF4C8E867D0A2968B2EB999 B3168216');
wireformat_ok('example.com.            TLSA       3 1 1 d2abde240d7cd3ee6b4b28c54df034b9 7983a1d16e8a410e4561cb106618e971');
wireformat_ok('example.com.            TXT        "system manager: jdoe@example.com"');
wireformat_ok('host.example.com.       WKS        192.0.2.3 TCP (ftp smtp telnet)');

done_testing;
