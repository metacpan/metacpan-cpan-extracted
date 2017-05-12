#!/usr/bin/env perl

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use lib 't';
use NewsML_G2_Test_Helpers qw(create_ni_video validate_g2 :vars);

use warnings;
use strict;

use XML::NewsML_G2;


sub remotes_checks {
    my ($dom, $xpc) = @_;

    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@width'),
        qr|1920|, 'resolution in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@size'),
        qr|23013531|, 'correct size in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@href'),
        qr|file://tmp/files/123.*mp4|, 'correct href in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@audiochannels'),
        qr|apaadc:stereo|, 'correct audiochannel in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@duration'),
        qr/30/, 'correct duration in XML');
    like($xpc->findvalue('//nar:contentMeta/nar:icon/@rendition'),
        qr/rnd:highRes/, 'rendition with qcode');
    like($xpc->findvalue('//nar:contentMeta/nar:icon/@href'),
        qr/456.jpg/, 'correct filename');

    return;
}

my %schemes;
foreach (qw(crel desk geo svc role ind org topic hltype adc)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(
        alias => "apa$_",
        uri => "http://cv.apa.at/$_/",
        catalog => "http://www.apa-it.at/NewsML_G2/apa_it_catalog_4.xml"
    );
}

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');
my $ni = create_ni_video();
my $hd = XML::NewsML_G2::Video->new(width => 1920, height => 1080, size => '23013531', duration => 30, audiochannels => 'stereo', mimetype => 'video/mp4');
my $sd = XML::NewsML_G2::Video->new(width => 720, height => 480, size => '5013531', duration => 30, mimetype => 'video/mp4');
$ni->add_remote('file://tmp/files/123.hd.mp4', $hd);
$ni->add_remote('file://tmp/files/123.sd.mp4', $sd);
my $icon1 = XML::NewsML_G2::Icon->new(rendition => 'highRes', href=>'file:///tmp/123.jpg', width => 1920, height => 1080);
my $icon2 = XML::NewsML_G2::Icon->new(rendition => 'thumbnail', href=>'file:///tmp/456.jpg', width => 1280, height => 720);
$ni->add_icon($icon1);
$ni->add_icon($icon2);
my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm, g2_version => 2.9);

# 2.9 checks
ok(my $dom = $writer->create_dom(), 'create DOM');
#diag($dom->serialize(1));
ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
$xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
$xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
remotes_checks($dom, $xpc);
validate_g2($dom, '2.9');

# 2.12, 2.15, 2.18 checks
foreach my $version (qw(2.12 2.15 2.18)) {
    ok($writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm, g2_version => $version), "creating $version writer");
    ok($dom = $writer->create_dom(), "$version writer creates DOM");
    #diag($dom->serialize(1));
    ok($xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
    $xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
    $xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    remotes_checks($dom, $xpc);
    validate_g2($dom, $version);
    #diag($dom->serialize(1));
}

done_testing;
