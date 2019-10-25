#!/usr/bin/env perl

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use lib 't';
use NewsML_G2_Test_Helpers
    qw(create_ni_text create_ni_picture validate_g2 :vars);

use warnings;
use strict;

use XML::NewsML_G2;

sub basic_checks {
    my ( $dom, $xpc, $ic ) = @_;

    like( $xpc->findvalue('//nar:copyrightHolder/nar:name'),
        qr/APA/, 'correct copyright in XML' );
    like( $xpc->findvalue('//nar:copyrightNotice'),
        qr/www.apa.at/, 'correct copyright notice in XML' );
    like( $xpc->findvalue('//nar:usageTerms'),
        qr/full beer/, 'correct usage terms in XML' );
    is( $xpc->findvalue('//nar:provider/@qcode'),
        'nprov:apa', 'correct provider in XML' );
    is( $xpc->findvalue('//nar:itemClass/@qcode'),
        "ninat:$ic", 'correct item class in XML' );
    is( $xpc->findvalue('//nar:embargoed'),
        $embargo, 'correct embargo in XML' );
    like( $xpc->findvalue('//nar:edNote[contains(@role, "embargo")]'),
        qr/\Q$embargo_text\E/, 'correct embargo text in XML' );
    is( $xpc->findvalue('//nar:contentCreated'),
        $time1, 'contentCreated correct' );
    is( $xpc->findvalue('//nar:contentModified'),
        $time2, 'contentModified correct' );

    is( $xpc->findvalue('//nar:pubStatus/@qcode'),
        'stat:usable', 'correct pubStatus in XML' );
    like( $xpc->findvalue('//nar:service/nar:name'),
        qr/Basisdienst/, 'correct service in XML' );
    ok( $xpc->find('//nar:signal[@qcode="apaind:bild"]'),
        'indicator for BILD found' );
    ok( $xpc->find('//nar:signal[@qcode="apaind:video"]'),
        'indicator for VIDEO found' );
    like( $xpc->findvalue('//nar:edNote[contains(@role, "closing")]'),
        qr/Schluss/, 'correct closing in XML' );
    like(
        $xpc->findvalue('//nar:edNote[contains(@role, "note")]'),
        qr/Bilder zum /,
        'correct note in XML'
    );
    like( $xpc->findvalue('//nar:located/nar:name'),
        qr/Wien/, 'correct city in XML' );
    is( $xpc->findvalue('//nar:altId'), $apa_id, 'correct AltId in XML' );
    is( $xpc->findvalue('//nar:genre[1]/@qcode'),
        'genre:Current', 'correct genre 1 in XML' );
    is( $xpc->findvalue('//nar:genre[2]/@qcode'),
        'genre:Extra', 'correct genre 2 in XML' );
    like( $xpc->findvalue('//nar:subject/@qcode'),
        qr/apadesk:CI/, 'desk in XML' );
    is( $xpc->findvalue('//nar:creditline'),
        $creditline, 'correct creditline in XML' );
    is( $xpc->findvalue('//nar:geoAreaDetails/nar:position/@latitude'),
        48.2000, 'correct latitude found' );

    foreach (@keywords) {
        like( $xpc->findvalue('//nar:keyword'),
            qr/$_/, 'correct keyword in XML' );
    }

    is( $xpc->findvalue('//nar:slugline'),
        $slugline, 'correct slugline in XML' );
    is( $xpc->findvalue('//nar:headline[@role="apahltype:title"]'),
        $title, 'correct title in XML' );
    is( $xpc->findvalue('//nar:headline[@role="apahltype:subtitle"]'),
        $subtitle, 'correct subtitle in XML' );
    is( $xpc->findvalue('//nar:contentSet/nar:inlineXML/@contenttype'),
        'application/xhtml+xml', 'correct contenttype in XML' );
    is( $xpc->findvalue('//xhtml:title'),
        $title, 'correct title in HTML head' );

    ok( my $xml_string = $dom->serialize(1), 'serializes into string' );
    unlike( $xml_string, qr/(HASH|ARRAY|SCALAR)\(/,
        'no perl references in XML' );

    return;
}

my %schemes;
foreach (qw(crel desk geo svc role ind org topic hltype)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(
        alias => "apa$_",
        uri   => "http://cv.apa.at/$_/"
    );
}

ok( my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes),
    'create Scheme Manager' );

foreach my $ni ( create_ni_text(), create_ni_picture() ) {

    ( my $ic ) = reverse split( '_', $ni->meta->name );

    my $writer = XML::NewsML_G2::Writer::News_Item->new(
        news_item      => $ni,
        scheme_manager => $sm,
        g2_version     => 2.9
    );

    my $paragraphs = $writer->create_element('paragraphs');
    for my $t (@text) {
        $paragraphs->appendChild(
            $writer->create_element(
                'p',
                _ns   => $writer->xhtml_ns,
                _text => $t
            )
        );
    }
    my $correct_guid =
        ( $ni->nature eq 'picture' ? $guid_picture : $guid_text );

    ok( $ni->paragraphs($paragraphs), 'set paragraphs' );

    # 2.9 checks
    ok( my $dom = $writer->create_dom(), 'create DOM' );
    ok( my $xpc = XML::LibXML::XPathContext->new($dom),
        'create XPath context for DOM tree' );
    $xpc->registerNs( 'nar',   'http://iptc.org/std/nar/2006-10-01/' );
    $xpc->registerNs( 'xhtml', 'http://www.w3.org/1999/xhtml' );
    basic_checks( $dom, $xpc, lc $ic );
    is( $xpc->findvalue('nar:newsItem/@guid'),
        $correct_guid, 'correct guid in XML' );
    like( $xpc->findvalue('//nar:infoSource/@literal'),
        qr/DPA/, 'correct source in XML, 2.9-style' );
    like( $xpc->findvalue('//nar:creator/@literal'),
        qr/dw.*dk.*wh/, 'correct authors in XML, 2.9-style' );
    validate_g2( $dom, '2.9' );

    # 2.12, 2.15 2.18 checks
    for my $version (qw(2.12 2.15 2.18)) {
        ok( $writer = XML::NewsML_G2::Writer::News_Item->new(
                news_item      => $ni,
                scheme_manager => $sm,
                g2_version     => $version
            ),
            "creating $version writer"
        );
        ok( $dom = $writer->create_dom(), "$version writer creates DOM" );
        ok( $xpc = XML::LibXML::XPathContext->new($dom),
            'create XPath context for DOM tree'
        );
        $xpc->registerNs( 'nar',   'http://iptc.org/std/nar/2006-10-01/' );
        $xpc->registerNs( 'xhtml', 'http://www.w3.org/1999/xhtml' );
        basic_checks( $dom, $xpc, lc $ic );
        is( $xpc->findvalue('nar:newsItem/@guid'),
            $correct_guid, 'correct guid in XML' );
        like( $xpc->findvalue('//nar:infoSource/nar:name'),
            qr/DPA/, "correct source in XML, $version-style" );
        like( $xpc->findvalue('//nar:creator/nar:name'),
            qr/dw.*dk.*wh/, "correct authors in XML, $version-style" );
        like( $xpc->findvalue('//nar:copyrightHolder/@uri'),
            qr/http:\/\/www.apa.at/, 'correct uri in xml' );
        validate_g2( $dom, $version );

        #diag($dom->serialize(1));
    }

}
done_testing;
