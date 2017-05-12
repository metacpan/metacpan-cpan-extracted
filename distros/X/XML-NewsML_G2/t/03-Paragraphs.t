#!/usr/bin/env perl

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use warnings;
use strict;

use XML::NewsML_G2;

use lib 't';
use NewsML_G2_Test_Helpers qw(create_ni_text @text);

my $ni = create_ni_text();

ok($ni->add_paragraph($text[0]), 'add_paragraph returns OK');
ok($ni->add_paragraph($text[1]), 'add_paragraph returns OK again');

my %schemes;
foreach (qw(crel desk geo svc role ind org topic hltype)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(alias => "apa$_", uri => "http://cv.apa.at/$_/");
}

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');

my $writer = XML::NewsML_G2::Writer::News_Item->new(news_item => $ni, scheme_manager => $sm);

ok(my $dom = $writer->create_dom(), 'create DOM');

ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
$xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');

ok(my @ps = $xpc->findnodes('//xhtml:p'), 'found paragraphs');

is($ps[0]->textContent, $text[0], 'paragraph 1 is correct');
is($ps[1]->textContent, $text[1], 'paragraph 2 is correct');

done_testing;
