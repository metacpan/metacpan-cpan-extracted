#!perl
use Test::Most 'die';
BEGIN {
eval 'use XML::LibXML';
plan skip_all => 'XML::LibXML needed for this test' if $@;
}
plan tests => 2;
use strict;
use warnings;
use Tree::Template::Declare -prefix=> 'x', builder => '+LibXML';
use Tree::Template::Declare -prefix=> 'd', builder => '+DAG_Node';

xxmlns test => 'http://test/';

my $xmltree= xtree {
    xnode {
        xname 'stuff';
        xnode {
            xname 'test:elem1';
            xattribs id => 1, 'test:buh' => 'testing';
            xnode {
                xname 'test:sub1';
            }
        };
        xnode {
            xname 'elem2';
            xattribs id => 2;
        };
    };
};

is($xmltree->toStringC14N(0),
   qq{<stuff><test:elem1 xmlns:test="http://test/" id="1" test:buh="testing"><test:sub1></test:sub1></test:elem1><elem2 id="2"></elem2></stuff>},
   'XML document'
);

my $dagtree=dtree {
    dnode {
        dname 'root';
        dattribs name => 'none';
        dnode {
            dname 'coso1';
            dattribs name => 'coso_1';
        };
        dnode {
            dname 'coso2';
        };
    };
};

cmp_deeply($dagtree->tree_to_lol(),
           [[re(qr{coso1})],[re(qr{coso2})],re(qr{root})],
           'DAG_Node tree');
