#!perl
use Test::Most 'die';
BEGIN {
eval 'use HTML::Element';
plan skip_all => 'HTML::Element needed for this test' if $@;
}
plan tests => 1;
use strict;
use warnings;
use Tree::Template::Declare builder => '+HTML_Element';

my $tree=tree {
    node {
        name 'html';
        node {
            name 'head';
            node {
                name 'title';
                text_node 'Page title';
            }
        };
        node {
            name 'body';
            node {
                name 'p';
                attribs id => 'p1';
                attribs class => 'para';
                text_node 'Page para';
            };
        };
    };
};

my $expected_tree = HTML::Element->new_from_lol(
    ['html',
     ['head',
      ['title','Page title'],
     ],
     ['body',
      ['p','Page para',{class=>'para',id=>'p1'}],
     ],
    ],
);
ok($tree->same_as($expected_tree),
   'HTML tree'
);
