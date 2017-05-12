#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use WWW::Google::Contacts::Type::Relation;

my $rel_with_type = WWW::Google::Contacts::Type::Relation->new(
    { type => "child", value => "Arne" } );
my $xml_hashref = $rel_with_type->to_xml_hashref;
is $xml_hashref->{rel},     'child';
is $xml_hashref->{content}, 'Arne';
ok !defined $xml_hashref->{label};

my $rel_with_label = WWW::Google::Contacts::Type::Relation->new(
    { label => "stripe buddy", value => "Arne" } );
$xml_hashref = $rel_with_label->to_xml_hashref;
is $xml_hashref->{label},   'stripe buddy';
is $xml_hashref->{content}, 'Arne';
ok !defined $xml_hashref->{rel};

# if given label is a defined relation type, use that type
$rel_with_label = WWW::Google::Contacts::Type::Relation->new(
    { label => "mother", value => "Arne" } );
$xml_hashref = $rel_with_label->to_xml_hashref;
is $xml_hashref->{rel},     'mother';
is $xml_hashref->{content}, 'Arne';
ok !defined $xml_hashref->{label};

done_testing;
