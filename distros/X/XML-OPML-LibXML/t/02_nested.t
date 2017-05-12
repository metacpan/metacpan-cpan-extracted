use strict;
use Test::Base;
use XML::OPML::LibXML;

plan 'no_plan';

{
    my $doc = XML::OPML::LibXML->new->parse_file("t/samples/opml-nested.xml");
    my @outline = $doc->outline;
    is @outline, 1;
    is $outline[0]->title, 'Subscriptions';
    ok $outline[0]->is_container;

    my @children = $outline[0]->children;
    is @children, 2;
    is $children[0]->title, 'Foo';
    @children = $children[0]->children;
    is $children[0]->title, 'blog.bulknews.net';
    is $children[0]->html_url, 'http://blog.bulknews.net/mt/';

    my @title;
    $doc->walkdown(sub { push @title, $_[0]->title });

    is_deeply \@title, [ qw( Subscriptions Foo blog.bulknews.net Bar Baz Bulknews::Subtech ) ];
}





