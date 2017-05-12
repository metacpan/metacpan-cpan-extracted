#!perl
package main;
use Test::Most 'die';
BEGIN {
eval 'use Tree::DAG_Node::XPath 0.10; require Tree::Transform::XSLTish';
plan skip_all => 'Tree::DAG_Node::XPath 0.10 and Tree::Transform::XSLTish needed for this test' if $@;
}
plan tests => 3;

package Copy;{
use Tree::Transform::XSLTish;
use Tree::Template::Declare::DAG_Node;
use Tree::Template::Declare builder => Tree::Template::Declare::DAG_Node->new('Tree::DAG_Node::XPath');
use strict;
use warnings;

tree_rule match => '/', action => sub {
    tree {
        $_[0]->apply_rules;
    };
};

tree_rule match => '*', priority => 0, action => sub {
    node {
        name $_[0]->it->name;
        attribs %{$_[0]->it->attributes};
        $_[0]->apply_rules;
    };
};

}

package main;
use strict;
use warnings;
use Tree::Template::Declare builder => Tree::Template::Declare::DAG_Node->new('Tree::DAG_Node::XPath');

my $tree=tree {
    node {
        name 'root';
        attribs name => 'none';
        node {
            name 'coso1';
            attribs name => 'coso_1';
        };
        node {
            name 'coso2';
            node {
                name 'coso3';
            };
        };
    };
};

diag "transforming";
my $trans=Copy->new();
my ($tree2)=$trans->transform($tree);

ok(defined $tree,'built');
ok(defined $tree2,'transformed');

diag "comparing";
is($tree->tree_to_lol_notation(),
   $tree2->tree_to_lol_notation(),
   'tree copy');

