#!perl
package main;
use Test::Most tests=>7;
use strict;
use warnings;
use Tree::DAG_Node::XPath;

my $tree=Tree::DAG_Node::XPath->new();
$tree->name('base');
$tree->new_daughter->name("coso$_") for 1..5;

warning_like { eval <<'PACK' } [qr/duplicate rule name/i],'Name collision';
package BadTransform;{
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 tree_rule name => 'one', action => sub { };

 tree_rule name => 'one', action => sub { };

 tree_rule match => '*', action => sub { };
 tree_rule match => '*', action => sub { };

 tree_rule match => 'coso1', priority=> 5, action => sub { $_[0]->call_rule('not-there') };
}
PACK

my $trans=BadTransform->new();

throws_ok { $trans->transform($tree) } qr/no valid rule/i,'No rule found';

throws_ok { $trans->apply_rules($tree) } qr/ambiguous rule/i,'Priority collision';

warning_like { $trans->apply_rules() } qr/without nodes nor context/i,'Apply without nodes';

warning_like { $trans->call_rule() } qr/without a rule name/i,'Call without name';

warning_like { $trans->call_rule('one') } qr/without context/i,'Call without context';

throws_ok { $trans->apply_rules($tree->findnodes('coso1')) } qr/no rule named not-there/i, 'Call with bad name';
