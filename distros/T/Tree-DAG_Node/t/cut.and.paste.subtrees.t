use strict;
use warnings;

use Test::More;

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

my($count) = 0;
my($tree)  = grow_tree;

ok(1 == 1, '1: Grow tree'); $count++;

my($drawing_1)  = join('', map{s/\s+$//; "$_\n"} @{$tree -> draw_ascii_tree});
my($expected_1) = <<'EOS';
                 |
              <Root>
 /---+---+---+---+---+---+---+---\
 |   |   |   |   |   |   |   |   |
<I> <H> <J> <J> <L> <D> <E> <F> <B>
 |   |   |   |   |   |   |   |   |
<J> <J> <K> <L> <M> <F> <F> <G> <C>
                 |
                <N>
                 |
                <O>
EOS

ok($drawing_1 eq $expected_1, '2: draw_ascii_tree() before cut-and-paste returned expected string'); $count++;

my($drawing_2)  = join('', map{s/\s+$//; "$_\n"} @{$tree -> tree2string});
my($expected_2) = <<'EOS';
Root. Attributes: {# => "0"}
    |--- I. Attributes: {# => "1"}
    |    |--- J. Attributes: {# => "1"}
    |--- H. Attributes: {# => "2"}
    |    |--- J. Attributes: {# => "2"}
    |--- J. Attributes: {# => "3"}
    |    |--- K. Attributes: {# => "3"}
    |--- J. Attributes: {# => "4"}
    |    |--- L. Attributes: {# => "4"}
    |--- L. Attributes: {# => "5"}
    |    |--- M. Attributes: {# => "5"}
    |         |--- N. Attributes: {# => "5"}
    |              |--- O. Attributes: {# => "5"}
    |--- D. Attributes: {# => "6"}
    |    |--- F. Attributes: {# => "6"}
    |--- E. Attributes: {# => "7"}
    |    |--- F. Attributes: {# => "7"}
    |--- F. Attributes: {# => "8"}
    |    |--- G. Attributes: {# => "8"}
    |--- B. Attributes: {# => "9"}
         |--- C. Attributes: {# => "9"}
EOS

ok($drawing_2 eq $expected_2, '3: tree2string() before cut-and-paste returned expected string'); $count++;

process_tree($tree);

ok(1 == 1, '4: Process tree'); $count++;

my($drawing_3)  = join('', map{s/\s+$//; "$_\n"} @{$tree -> draw_ascii_tree});
my($expected_3) = <<'EOS';
             |
          <Root>
   /-------+-----+---+---\
   |       |     |   |   |
  <I>     <H>   <D> <E> <B>
 /---\   /---\   |   |   |
 |   |   |   |  <F> <F> <C>
<J> <J> <J> <J>  |   |
 |   |   |   |  <G> <G>
<K> <L> <K> <L>
     |       |
    <M>     <M>
     |       |
    <N>     <N>
     |       |
    <O>     <O>
EOS

ok($drawing_3 eq $expected_3, '5: draw_ascii_tree() after cut-and-paste returned expected string'); $count++;

my($drawing_4)  = join('', map{s/\s+$//; "$_\n"} @{$tree -> tree2string});
my($expected_4) = <<'EOS';
Root. Attributes: {# => "0"}
    |--- I. Attributes: {# => "1"}
    |    |--- J. Attributes: {replaced => "1"}
    |    |    |--- K. Attributes: {}
    |    |--- J. Attributes: {replaced => "1"}
    |         |--- L. Attributes: {replaced => "1"}
    |              |--- M. Attributes: {}
    |                   |--- N. Attributes: {}
    |                        |--- O. Attributes: {}
    |--- H. Attributes: {# => "2"}
    |    |--- J. Attributes: {replaced => "1"}
    |    |    |--- K. Attributes: {}
    |    |--- J. Attributes: {replaced => "1"}
    |         |--- L. Attributes: {replaced => "1"}
    |              |--- M. Attributes: {}
    |                   |--- N. Attributes: {}
    |                        |--- O. Attributes: {}
    |--- D. Attributes: {# => "6"}
    |    |--- F. Attributes: {replaced => "1"}
    |         |--- G. Attributes: {}
    |--- E. Attributes: {# => "7"}
    |    |--- F. Attributes: {replaced => "1"}
    |         |--- G. Attributes: {}
    |--- B. Attributes: {# => "9"}
         |--- C. Attributes: {# => "9"}
EOS

ok($drawing_4 eq $expected_4, '6: tree2string() after cut-and-paste returned expected string'); $count++;

done_testing($count);

diag "Warning: Don't try this at home kids. Some trees get into an infinite loop.";
