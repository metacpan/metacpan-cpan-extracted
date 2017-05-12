# -*- perl -*-

use strict;
use warnings;

package Test;

use base qw(XML::LibXML::Transformer);

sub link {
    my ($self, $attr, $node, @args) = @_;

    Test::More::is($attr->{id}, "Michael");
    Test::More::is($attr->{size}, 400);
    Test::More::is($node->to_literal, "WOO");
    
    Test::More::is($args[0], "ARG");

    return "<changed>YES</changed>"
}

sub page {
    my ($self, $attr, $node, @args) = @_;
    
    Test::More::is($attr->{id}, "Robert");
    Test::More::is($attr->{size}, 600);
    
    Test::More::is($args[0], "ARG");

    return undef;
}

package main;

use XML::LibXML::Enhanced qw(parse_xml_string);
use Test::More qw(no_plan);

my $t = Test->new("http://beebo.org/xsl/image");

my $doc = parse_xml_string(join('', <DATA>));

$t->transform($doc, "ARG");

is($doc->documentElement->findvalue("/root/p/changed"), "YES");
is($doc->findvalue('/root/baz/@name'), "Baz");
is($doc->findvalue('/root/p/image:page/@id'), "Robert");

__DATA__
<root xmlns:image="http://beebo.org/xsl/image">

<p>
<image:link id="Michael" size="400">WOO</image:link>
<image:page id="Robert" size="600"/>
</p>

<baz name="Baz"/>

</root>
