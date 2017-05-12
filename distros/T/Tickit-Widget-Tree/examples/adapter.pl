#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Async;
use Tickit::Widget::Tree;

my $tree = Tree::DAG_Node->random_network({ max_depth => 20, min_depth => 6, max_children => 3, max_node_count => 5000 }); # Tree::DAG_Node->new;
$tree->name('Root');
$tree->walk_down({ callback => sub { shift->attributes->{open} = 0 } });
$tree->attributes->{open} = 1;
my $adapter;
my $n;
$tree->add_daughter($n = Tree::DAG_Node->new({name => 'one'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'one.one'}));
$tree->add_daughter($n = Tree::DAG_Node->new({name => 'two'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'two.one'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'two.two'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'two.three'}));
$n->attributes->{open} = 1;
$tree->add_daughter($n = Tree::DAG_Node->new({name => 'three'}));
$n->add_daughter(Tree::DAG_Node->new({name => "three.$_"})) for qw(one two three four five six seven);
$tree->add_daughter(Tree::DAG_Node->new({name => 'four'}));
# warn "$_\n" for @{$tree->tree2string};
my $w = Tickit::Widget::Tree->new(root => $tree);
my $tickit = Tickit::Async->new(
	root => do {
		$w->take_focus;
		$w
	}
);
{
	$tree->add_daughter(my $ab = Tree::DAG_Node->new({name => 'adapterized'}));
	my $adapter = $w->adapter_for_node($ab);
	$adapter->push([int 17*rand]) for 1..5;
	my $code;
	Scalar::Util::weaken(my $wt = $tickit);
	$code = sub {
		$adapter->push([int 17*rand])->on_done(
			$adapter->curry::shift
		);
		$wt->timer(
			after => 0.5,
			$code
		);
	};
	$code->();
}
$tickit->run;

