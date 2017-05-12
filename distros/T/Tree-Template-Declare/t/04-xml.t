#!perl
use Test::Most 'die';
BEGIN {
eval 'use XML::LibXML';
plan skip_all => 'XML::LibXML needed for this test' if $@;
}
plan tests => 2;
use strict;
use warnings;
use Tree::Template::Declare builder => '+LibXML';

xmlns test => 'http://test/';

sub make_tree {
    tree {
        node {
            name 'stuff';
            node {
                name 'test:elem1';
                attribs 'test:buh' => 'testing';
                attribs id => 1;
                node {
                    name 'test:sub1';
                    text_node 'some content';
                }
            };
            node {
                name 'elem2';
                attribs id => 2;
            };
        };
    };
}

{
my $tree=make_tree();

is($tree->toStringC14N(0),
   qq{<stuff><test:elem1 xmlns:test="http://test/" id="1" test:buh="testing"><test:sub1>some content</test:sub1></test:elem1><elem2 id="2"></elem2></stuff>},
   'XML document without default NS'
);
}

xmlns ':default' => 'ftp://test/';

{
my $tree=make_tree();

is($tree->toStringC14N(0),
   qq{<stuff xmlns="ftp://test/"><test:elem1 xmlns:test="http://test/" id="1" test:buh="testing"><test:sub1>some content</test:sub1></test:elem1><elem2 id="2"></elem2></stuff>},
   'XML document with default NS'
);
}
