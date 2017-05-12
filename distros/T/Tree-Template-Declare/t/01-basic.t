#!perl
use Test::Most tests => 2,'die';
use strict;
use warnings;
use Tree::Template::Declare builder => '+DAG_Node';

my $tree=tree {
    node {
        name 'root';
        attribs name => 'none';
        node {
            name 'coso1';
            attribs name => 'coso_1';
            attribs other => 'some';
        };
        node {
            name 'coso2';
        };
    };
};

cmp_deeply($tree->tree_to_lol(),
           [[re(qr{coso1})],[re(qr{coso2})],re(qr{root})],
           'built the tree');
is_deeply(($tree->daughters)[0]->attributes,
          {name => 'coso_1', other => 'some'},
          'attributes');
