#!/usr/bin/env perl

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use lib 't';
use NewsML_G2_Test_Helpers qw(create_ni_audio validate_g2 :vars);

use warnings;
use strict;

use XML::NewsML_G2;


sub remotes_checks {
    my ($dom, $xpc) = @_;

    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@size'),
        qr|23013531|, 'correct size in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@href'),
        qr|file://tmp/files/123.*mp3|, 'correct href in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@audiochannels'),
        qr|apaadc:stereo|, 'correct audiochannel in XML');
    like($xpc->findvalue('//nar:contentSet/nar:remoteContent/@duration'),
        qr/30/, 'correct duration in XML');

    return;
}

my %schemes;
foreach (qw(crel desk geo svc role ind org topic hltype adc)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(alias => "apa$_", uri => "http://cv.apa.at/$_/");
}

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');
my $ni = create_ni_audio();
my $mp3 = XML::NewsML_G2::Audio->new(size => '23013531', duration => 30, audiochannels => 'stereo', mimetype => 'audio/mpeg');
$ni->add_remote('file://tmp/files/123.mp3', $mp3);
my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm, g2_version => 2.9);

# 2.9 checks
ok(my $dom = $writer->create_dom(), 'create DOM');
ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
$xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
$xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
remotes_checks($dom, $xpc);
validate_g2($dom, '2.9');

# 2.12 2.15 2.18 checks
for my $version (qw(2.12 2.15 2.18)) {
    ok($writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm, g2_version => $version), "creating $version writer");
    ok($dom = $writer->create_dom(), "$version writer creates DOM");
    ok($xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
    $xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
    $xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    remotes_checks($dom, $xpc);
    validate_g2($dom, $version);
    #diag($dom->serialize(1));
}

done_testing;
