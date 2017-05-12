#!/usr/bin/env perl

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use lib 't';
use NewsML_G2_Test_Helpers qw(create_ni_text create_ni_picture create_ni_video validate_g2 :vars);

use warnings;
use strict;

use XML::NewsML_G2;


sub news_message_items_check {
    my ($xpc) = @_;

    like($xpc->findvalue('/nar:newsMessage/nar:itemSet/nar:newsItem/@guid'),
        qr|APA0379|, 'guid found');
    ok($xpc->find('//nar:newsItem/nar:itemMeta/nar:itemClass[@qcode="ninat:video"]'),
        'news message contains a video news item');
    ok($xpc->find('//nar:newsItem/nar:itemMeta/nar:itemClass[@qcode="ninat:text"]'),
        'news message contains a text news item');
    is($xpc->findnodes('/nar:newsMessage/nar:itemSet/*')->size(), 2,
        'two items found');
    is($xpc->findnodes('/nar:newsMessage/nar:itemSet/nar:newsItem')->size(), 2,
        'two news items found');
}

sub news_message_package_check {
    my ($xpc) = @_;

    ok($xpc->find(
       '/nar:newsMessage/nar:itemSet/nar:packageItem/nar:itemMeta/nar:itemClass[@qcode="ninat:composite"]'),
        'correct itemClass');
    ok($xpc->find('//nar:newsItem/nar:itemMeta/nar:itemClass[@qcode="ninat:text"]'),
        'news message contains a text news item');
    ok($xpc->find('//nar:newsItem/nar:itemMeta/nar:itemClass[@qcode="ninat:picture"]'),
        'news message contains a picture news item');
    ok($xpc->find('//nar:itemRef/nar:itemClass[@qcode="ninat:text"]'),
        'package in news message contains a ref to a text news item');
    ok($xpc->find('//nar:itemRef/nar:itemClass[@qcode="ninat:picture"]'),
        'package in news message contains a ref to a picture news item');
    is($xpc->findnodes('/nar:newsMessage/nar:itemSet/*')->size(), 3,
        'three items found');
    is($xpc->findnodes('/nar:newsMessage/nar:itemSet/nar:packageItem')->size(), 1,
        'one package item found');
    is($xpc->findnodes('/nar:newsMessage/nar:itemSet/nar:newsItem')->size(), 2,
        'two news items found found');
}


#News Item Test
my %schemes;
foreach (qw(crel desk geo svc role ind org topic hltype adc)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(
        alias => "apa$_", uri => "http://cv.apa.at/$_/"
    );
}

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');

my $ni_video = create_ni_video();
my $hd = XML::NewsML_G2::Video->new(width => 1920, height => 1080,
    size => '23013531', duration => 30, audiochannels => 'stereo', mimetype => 'video/mp4'
);
$ni_video->add_remote('file://tmp/files/123.hd.mp4', $hd);
my $ni_text = create_ni_text();

my $nm = XML::NewsML_G2::News_Message->new();
$nm->add_item($ni_video);
$nm->add_item($ni_text);

foreach my $version (qw(2.12 2.15 2.18)) {
    my $writer = XML::NewsML_G2::Writer::News_Message->new
        (news_message => $nm, scheme_manager => $sm, g2_version => $version);
    ok(my $dom = $writer->create_dom(), "$version create DOM");
    ok(my $xpc = XML::LibXML::XPathContext->new($dom),
       'create XPath context for DOM tree');
    $xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
    $xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    news_message_items_check($xpc);
    validate_g2($dom, $version);
}

#Package Item Test

my %args = (language => 'de', provider => $prov_apa);

ok(my $pi = XML::NewsML_G2::Package_Item->new(%args), 'create Package_Item');
isa_ok($pi->root_group, 'XML::NewsML_G2::Group', 'package\'s root group');
is_deeply($pi->root_group->items, [], 'root group is empty');

# for multimedia package: create news item + image, add them to root group
my $text = create_ni_text();
my $pic = create_ni_picture();
$pi->add_to_root_group($text, $pic);

cmp_ok(@{$pi->root_group->items}, '==', 2, 'root group has two items now');

%schemes = (group_mode => XML::NewsML_G2::Scheme->new(alias => 'pgrmod',
    catalog => 'http://www.iptc.org/std/catalog/catalog.IPTC-G2-Standards_22.xml'));
foreach (qw(group svc ind)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(alias => "apa$_",
        uri => "http://cv.apa.at/$_/");
}
ok($sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');

$nm = XML::NewsML_G2::News_Message->new();
$nm->add_item($pi);
$nm->add_item($text);
$nm->add_item($pic);

foreach my $version (qw(2.12 2.15 2.18)) {
    my $writer = XML::NewsML_G2::Writer::News_Message->new
        (news_message => $nm, scheme_manager => $sm, g2_version => $version);
    ok(my $dom = $writer->create_dom(), "$version package writer creates DOM");
    ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
    $xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
    $xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    news_message_package_check($xpc);
    validate_g2($dom, $version);
}

done_testing();
