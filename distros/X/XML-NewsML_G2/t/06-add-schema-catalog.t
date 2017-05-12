#!/usr/bin/env perl

use utf8;
use Test::More;
use Test::Exception;
use XML::LibXML;
use XML::NewsML_G2;

use lib 't';
use NewsML_G2_Test_Helpers qw(validate_g2);

use warnings;
use strict;

ok(my $prov_apa = XML::NewsML_G2::Provider->new
  (qcode => 'apa', name => 'APA - Austria Presse Agentur'
  ), 'create Provider instance');

ok(my $org = XML::NewsML_G2::Organisation->new(name => 'Google', qcode => 'gogl'),
   'create Organisation instance');
ok($org->add_website('http://www.google.com/'), 'add_website works');


sub create_ni_text  {
    my (%args) = @_;

    ok(my $ni = XML::NewsML_G2::News_Item_Text->new
       (title => 'Saisonstart im Schweizerhaus: Run aufs Krügerl im Prater',
        language => 'de',
        provider => $prov_apa,
       ), 'create News Item instance');

    ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%args),
       'creating Scheme_Manager instance works');

    ok($ni->add_paragraph('Die Saison im Wiener Prater hat am Donnerstagvormittag mit der Eröffnung des Schweizerhauses begonnen - diese findet traditionell jedes Jahr am 15. März statt.'), 'add_paragraph works');


    ok($ni->add_organisation($org), 'add_organisation works');

    my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm);

    ok(my $dom = $writer->create_dom(), 'create DOM');
    #diag($dom->serialize(1));
    validate_g2($dom);
    return;
}

create_ni_text();

create_ni_text(org => XML::NewsML_G2::Scheme->new(alias => 'xyzorg', uri => 'http://xyz.org/cv/org'));

create_ni_text(org => XML::NewsML_G2::Scheme->new(alias => 'xyzorg', catalog => 'http://xyz.org/catalog_1.xml'));

throws_ok(sub {XML::NewsML_G2::Scheme->new(alias => 'xyzorg')}, qr/required/, 'creating Scheme without uri and catalog throws');

done_testing;
