#!/usr/bin/env perl

use utf8;
use Test::More;

use lib 't';
use NewsML_G2_Test_Helpers qw($prov_apa create_ni_text create_ni_picture validate_g2);

use warnings;
use strict;

use XML::NewsML_G2;


sub basic_checks {
    my ($xpc) = @_;
    $xpc->registerNs('nar', 'http://iptc.org/std/nar/2006-10-01/');
    is($xpc->findvalue('/nar:packageItem/nar:itemMeta/nar:itemClass/@qcode'), 'ninat:composite', 'correct itemClass');
    is($xpc->findvalue('/nar:packageItem/nar:groupSet/@root'), 'root_group', 'correct root group id');
    ok($xpc->find('/nar:packageItem/nar:groupSet/nar:group[@id="root_group"]'), 'group with correct id exists');
    ok($xpc->find('//nar:group/nar:itemRef'), 'group has itemref');
    return;
}


my %args = (language => 'de', provider => $prov_apa);

ok(my $pi = XML::NewsML_G2::Package_Item->new(%args), 'create Package_Item');
isa_ok($pi->root_group, 'XML::NewsML_G2::Group', 'package\'s root group');
is_deeply($pi->root_group->items, [], 'root group is empty');

# for multimedia package: create news item + image, add them to root group
my $text = create_ni_text();
my $pic = create_ni_picture();
$pi->add_to_root_group($text, $pic);

cmp_ok(@{$pi->root_group->items}, '==', 2, 'root group has two items now');

my %schemes = (pgrmod => XML::NewsML_G2::Scheme->new(alias => 'pgrmod', catalog => 'http://www.iptc.org/std/catalog/catalog.IPTC-G2-Standards_22.xml'));
foreach (qw(group)) {
    $schemes{$_} = XML::NewsML_G2::Scheme->new(alias => "apa$_", uri => "http://cv.apa.at/$_/");
}

ok(my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes), 'create Scheme Manager');

ok(my $writer = XML::NewsML_G2::Writer::Package_Item->new(package_item => $pi, scheme_manager => $sm), 'create package writer');

ok(my $dom = $writer->create_dom(), 'package writer creates DOM');
ok(my $xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');

basic_checks($xpc);
validate_g2($dom);
#diag($dom->serialize(1));

# for slideshows: create several news items + images, each pair in its own group

my $title = 'Slideshow of the day';
ok($pi = XML::NewsML_G2::Package_Item->new(
       title => $title, root_role => 'slideshow', %args), 'create Package_Item');
$pi->root_group->mode('sequential');
for my $id (1 .. 4) {
    $text = create_ni_text(id => $id);
    $pic = create_ni_picture(id => $id);
    my $g = XML::NewsML_G2::Group->new(role => 'slide');
    $g->add_item($text, $pic);
    $pi->add_to_root_group($g);
}

# and add a final inner group, just for the kicks
my $last_group = $pi->root_group->items->[-1];
$last_group->add_item(my $inner_group = XML::NewsML_G2::Group->new(role => 'slide-in-a-slide'));
$text = create_ni_text(id => 42);
$pic = create_ni_picture(id => 42);
$inner_group->add_item($text, $pic);

ok($writer = XML::NewsML_G2::Writer::Package_Item->new(package_item => $pi, scheme_manager => $sm), 'create package writer');

ok($dom = $writer->create_dom(), 'package writer creates DOM');
ok($xpc = XML::LibXML::XPathContext->new($dom), 'create XPath context for DOM tree');
basic_checks($xpc);
is($xpc->find('//nar:packageItem/nar:itemMeta/nar:title'), $title, 'package title correct');
ok($xpc->find('//nar:group[@id="root_group"]/nar:groupRef'), 'slideshow has grouprefs');
ok($xpc->find('//nar:group[@id="group_4"]/nar:groupRef'), 'last group has groupref');
is($xpc->findvalue('//nar:group[@id="root_group"]/@role'), 'apagroup:slideshow', 'slideshow has correct role');
is($xpc->findvalue('//nar:group[@id="root_group"]/@mode'), 'pgrmod:seq', 'slideshow has correct mode');

validate_g2($dom);
#diag($dom->serialize(1));


done_testing;
