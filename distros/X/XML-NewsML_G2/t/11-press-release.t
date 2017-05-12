#!/usr/bin/env perl

use utf8;
use Test::More;
use XML::LibXML;
use XML::NewsML_G2;

use lib 't';
use NewsML_G2_Test_Helpers qw(validate_g2);

use warnings;
use strict;

ok(my $prov_apa = XML::NewsML_G2::Provider->new
  (qcode => 'apa', name => 'APA - Austria Presse Agentur'
  ), 'create Provider instance');

ok(my $svc = XML::NewsML_G2::Service->new
   (qcode => 'ots', name => 'APA-OTS Originaltext-Service'
   ), 'create OTS service');

ok(my $kolarik = XML::NewsML_G2::Copyright_Holder->new

   (qcode => '12345', name => "Karl Kolarik's Schweizerhaus GmbH",
    notice => 'OTS-Originaltext Presseaussendung unter ausschliesslicher inhaltlicher Verantwortung des Aussenders',
    uri => 'http://www.schweizerhaus.at/copyright.html'
   ), 'create copyright holder');

ok(my $ni = XML::NewsML_G2::News_Item_Text->new
   (title => 'Saisonstart im Schweizerhaus: Run aufs Krügerl im Prater',
    language => 'de',
    provider => $prov_apa,
    service => $svc,
    copyright_holder => $kolarik,
   ), 'create News Item instance');

ok($ni->add_paragraph('Die Saison im Wiener Prater hat am Donnerstagvormittag mit der Eröffnung des Schweizerhauses begonnen - diese findet traditionell jedes Jahr am 15. März statt.'), 'add_paragraph works');

my %schemes;
foreach (qw(svc)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(alias => "apa$_", uri => "http://cv.apa.at/$_/");
}
$schemes{copyright_holder} = XML::NewsML_G2::Scheme->new(alias => "apaotsem", uri => "http://cv.apa.at/apaotsem/");

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');

my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm);
ok(my $dom = $writer->create_dom(), 'create DOM');

#diag($dom->serialize(1));

ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
$xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
$xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');

# copyright holder
like($xpc->findvalue('//nar:rightsInfo/nar:copyrightHolder/nar:name'),
     qr/Kolarik/, 'correct copyrightholder name in XML');
is($xpc->findvalue('//nar:rightsInfo/nar:copyrightHolder/@qcode'),
   'apaotsem:12345', 'correct copyrightholder qcode in XML');
like($xpc->findvalue('//nar:rightsInfo/nar:copyrightHolder/@uri'),
    qr/www\.schweizerhaus\.at/,'correct URI in XML of copyrightholder');
like($xpc->findvalue('//nar:rightsInfo/nar:copyrightNotice'),
     qr/Aussender/, 'correct copyrightnotice in XML');

# provider
is($xpc->findvalue('//nar:provider/@qcode'), 'nprov:apa', 'correct provider qcode in XML');
like($xpc->findvalue('//nar:provider/nar:name'),
     qr/Austria Presse Agentur/, 'correct provider name in XML');

#service
is($xpc->findvalue('//nar:service/@qcode'), 'apasvc:ots', 'correct service qcode in XML');
like($xpc->findvalue('//nar:service/nar:name'),
     qr/APA-OTS/, 'correct service name in XML');

validate_g2($dom);

done_testing;
