#!/usr/bin/env perl

use strict;
use warnings;

use Tree::DAG_Node;

my($starting_node);

# -----------------------------------------------

sub grow_tree
{
	my($count) = 0;
	my($tree)  = Tree::DAG_Node -> new({name => 'Root', attributes => {'#' => $count} });
	my(%child) =
	(
		I => 'J',
		H => 'J',
		J => 'L',
		L => 'M',
		D => 'F',
		E => 'F',
		F => 'G',
		B => 'C',
	);

	my($child);
	my($kid_1, $kid_2);
	my($name, $node);

	for $name (qw/I H J J L D E F B/)
	{
		$count++;

		$node          = Tree::DAG_Node -> new({name => $name, attributes => {'#' => $count} });
		$child         = Tree::DAG_Node -> new({name => $child{$name}, attributes => {'#' => $count} });
		$starting_node = $node if ($name eq 'H');

		$child -> name('K') if ($count == 3);

		if ($child{$name} eq 'M')
		{
			$kid_1 = Tree::DAG_Node -> new({name => 'N', attributes => {'#' => $count}});
			$kid_2 = Tree::DAG_Node -> new({name => 'O', attributes => {'#' => $count}});

			$kid_1 -> add_daughter($kid_2);
			$child -> add_daughter($kid_1);
		}

		$node -> add_daughter($child);
		$tree -> add_daughter($node);
	}

	return $tree;

} # End of grow_tree.

# -----------------------------------------------

sub process_tree_helper
{
	my($tree)      = @_;
	my(@ancestors) = map{$_ -> name} $tree -> daughters;

	my(%ancestors);

	@ancestors{@ancestors} = (1) x @ancestors;

	my($attributes);
	my($name);
	my(@stack);

	$tree -> walk_down
	({
		ancestors => \%ancestors,
		callback  =>
		sub
		{
			my($node, $options) = @_;

			if ($$options{_depth} > 1)
			{
				$attributes = $node -> attributes;
				$name       = $node -> name;

				if (defined $$options{ancestors}{$name} && ! $$attributes{replaced})
				{
					push @{$$options{stack} }, $node;
				}
			}

			return 1;
		},
		_depth => 0,
		stack  => \@stack,
	});

	my($sub_tree) = Tree::DAG_Node -> new;

	my(@kids);
	my($node);
	my(%seen);

	for $node (@stack)
	{
		$name        = $node -> name;
		@kids        = grep{$_ -> name eq $name} $tree -> daughters;
		$seen{$name} = 1;

		$sub_tree -> add_daughters(map{$_ -> copy_at_and_under({no_attribute_copy => 1})} @kids);

		for ($sub_tree -> daughters)
		{
			$_ -> attributes({%{$_ -> attributes}, replaced => 1});
		}

		$node -> replace_with($sub_tree -> daughters);
	}

	return ({%seen}, $#stack);

} # End of process_tree_helper.

# ------------------------------------------------

sub process_tree
{
	my($tree)     = @_;
	my($finished) = 0;

	my(@result);
	my(%seen);

	while (! $finished)
	{
		@result   = process_tree_helper($tree);
		$seen{$_} = 1 for keys %{$result[0]};
		$finished = $result[1] < 0;
	}

	for my $child ($tree -> daughters)
	{
		$tree -> remove_daughter($child) if ($seen{$child -> name});
	}

} # End of process_tree.

# -----------------------------------------------

my($tree) = grow_tree;

my(@ascii_1)  = @{$tree -> draw_ascii_tree};
my(@string_1) = @{$tree -> tree2string};
my(@string_2) = @{$tree -> tree2string({no_attributes => 1})};
my(@string_3) = @{$tree -> tree2string({}, $starting_node)};

process_tree($tree);

print "1: draw_ascii_tree(): Before: \n";
print map{"$_\n"} @ascii_1;
print "2: draw_ascii_tree(): After: \n";
print map{"$_\n"} @{$tree -> draw_ascii_tree};
print '-' x 35, "\n";

print "3: tree2string(): Before: \n";
print map{"$_\n"} @string_1;
print "4: tree2string(): After: \n";
print map{"$_\n"} @{$tree -> tree2string};
print '-' x 35, "\n";

print "5: tree2string({no_attributes => 1}): Before: \n";
print map{"$_\n"} @string_2;
print "6: tree2string({no_attributes => 1}): After: \n";
print map{"$_\n"} @{$tree -> tree2string({no_attributes => 1})};
print '-' x 35, "\n";

print "5: tree2string({}, \$starting_node) before: \n";
print map{"$_\n"} @string_3;
print "6: tree2string({}, \$starting_node) after: \n";
print map{"$_\n"} @{$tree -> tree2string({}, $starting_node)};
print '-' x 35, "\n";

print "Warning: Don't try this at home kids. Some trees get into an infinite loop.\n";
