#!/usr/bin/env perl

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use lib 't';
use NewsML_G2_Test_Helpers qw(create_ni_text validate_g2 :vars);

use warnings;
use strict;

use XML::NewsML_G2;

my $ni = create_ni_text();

my %schemes;
foreach (qw(crel desk geo svc role ind org topic hltype)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(alias => "apa$_", uri => "http://cv.apa.at/$_/", catalog => "http://www.apa-it.at/NewsML_G2/apa_it_catalog_4.xml");
}

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');

ok(my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm), 'creating 2.15 writer');
ok(my $dom = $writer->create_dom(), '2.15 writer creates DOM');

ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
$xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');

ok(!$xpc->find('//nar:scheme'), 'no scheme is created in XML');
like($xpc->findvalue('//nar:catalogRef/@href'), qr/www.apa-it.at/, 'correct catalog ref found in XML');

#diag($dom->serialize(1));

validate_g2($dom);

done_testing;
