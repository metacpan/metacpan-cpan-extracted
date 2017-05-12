package Voting::Condorcet::RankedPairs;

use strict;
use warnings;
use Graph;
use Carp qw(croak);

our $VERSION = '1.01';

# Our majorities are in positon 2 of our stored pairs array.
use constant INDEX_MAJORITY => 2; 

use constant RANGE_MIN    => 0;
use constant RANGE_MAX    => 1;
use constant HALF_RANGE   => (RANGE_MIN + RANGE_MAX) / 2;

=head1 NAME

Voting::Condorcet::RankedPairs - Ranked Pairs voting resolution.

=head1 SYNOPSIS

  use Voting::Condorcet::RankedPairs;

  my $rp = Voting::Condorcet::RankedPairs->new();

  $rp->add('Alice', 'Bob', 0.7);	# Alice got 70% votes, Bob 30%
  $rp->add('Alice', 'Eve', 0.4);	# Alice got 40% votes, Eve 60%

  my $winner    = $rp->winner;		# The winner, ignores ties.
  my @winners   = $rp->strict_winners;	# All winners, allows ties.

  my @rankings  = $rp->rankings;	# All entries, best to worst.
  my @rankings2 = $rp->strict_rankings;	# All entries, allowing ties.

  my @better = $rp->better_than('Alice'); # Entries significantly better
  					  # than Alice.

  my @worse  = $rp->worse_than('Alice');  # Entries significantly worse
  					  # than Alice.

  my $graph  = $rp->graph;		# Underlying Graph object used.
  					# (Advanced users only)

  $rp->compile;				# Force graph compilation.
  					# (Advanced users only)

=head1 DESCRIPTION

This module implements a I<Ranked Pairs> Condorcet voting system,
as described at L<http://en.wikipedia.org/wiki/Ranked_Pairs>.

Ranked pairs uses a directed graph to determine the winner and
rankings from a series of pairwise comparisons.

=cut

my %DEFAULTS = (
	ordered_input => 0,
);

=head2 new

   my $rp  = Voting::Condorcet::RankedPairs->new();
   my $rp2 = Voting::Condorcet::RankedPairs->new(ordered_input => 1);

This method creates a new Ranked Pairs object.  The C<ordered_input>
option, if set, allows the module to perform a number of time and
space optimisations, but requires that data be added in strict
most-significant to least-significant order.

=cut

sub new {
	my ($class, @args) = @_;

	my $this = bless({},$class);

	$this->_init(@args);

	return $this;
}

sub _init {
	my $this = shift;
	my %args = (%DEFAULTS,@_);

	$this->{ordered_input}         = $args{ordered_input};
	$this->{graph} = Graph->new;
	$this->{pairs} = [];
	$this->{max_dist} = HALF_RANGE;

	return $this;
}

=head2 add

  $rp->add('Alice','Bob',0.7);	# Alice vs Bob, Alice gets 70% votes
  $rp->add('Bob','Eve',0.4);    # Bob vs Eve,   Bob gets only 40% votes

This method adds the results of a pairwise contest.  It always
takes exactly three arguments: the two contestants, and a fractional
number between 0 and 1 indicating the number of votes in favour
of the first contestant.

A score of 0.5 indicates a tie, a score of 1.00 would indicate all
votes fell to the first contestant, and a score of 0.00 would indicate
all votes fell to the second.

If C<ordered_input> was set when the object was created, then
contests must be added in order of most relevance (scores furthest
from 0.50) to least relevance (scores closest to 0.50).  Adding
scores out of order when C<ordered_input> is set will result in
an exception.

Scores of exactly 0.5 result in the contestants being added to
the graph, but no edge being drawn.

=cut

sub add {
	my ($this, $winner, $loser, $result) = @_;

	if (@_ != 4) {
		croak("add() must be given two nodes and a result (received:".join(",",@_));
	}

	if ($result < RANGE_MIN or $result > RANGE_MAX) {
		croak "add() must be given a fractional result between 0 and 1.  Received $result";
	}

	# If it's an exact draw, then add the nodes to the graph,
	# but no edge.  We can do this immediately.

	if ($result == HALF_RANGE) {
		$this->_graph->add_vertex($winner)->add_vertex($loser);
		return;
	}

	# We assume that $winner beats $loser.  Swap them
	# around if this is not currently correct.
	
	($winner,$loser) = ($loser,$winner) if ($result < HALF_RANGE);

	if ($this->{ordered_input}) {

		# Results must be fed to us in most-significant
		# to least significant order.  We check that here.
		# If we're given results out of order, then an
		# exception is thrown.

		my $distance = abs(HALF_RANGE - $result);
		my $max_dist = $this->{max_dist};
		if ($distance > $max_dist) {
			croak "Out of order pair detected in ordered_input mode.  ($winner,$loser) has a majority of $distance, where it must be less than $max_dist";
		}
		$this->{max_dist} = $distance;

		$this->_add($winner,$loser);
	} else {
		push(@{$this->{pairs}},[$winner,$loser,$result]);
	}

	return;
}

# This actually inserts an edge into our voting graph.
# It assumes it's being called with the correct arguments.

sub _add {
	my ($this,$winner,$loser) = @_;

	my $graph = $this->_graph;

	$graph->add_edge($winner,$loser);

	# If we just made a cycle, then reverse our action.
	if ($graph->is_cyclic) {
		$graph->delete_edge($winner,$loser);
	}

	return;
}

=head2 winner

  my $winner = $rp->winner;

This returns the 'winner' of the competition.  This always returns
a single result, and does not check for draws.  Use L<strict_winners>
(below) if a draw may exist.

=cut

sub winner {
	croak "Useless call to winner in void context" if not defined wantarray;
	return ($_[0]->strict_winners)[0];
}

=head2 strict_winners

  my @winners = $rp->strict_winners;

In some cirumstances two or more entries can be considered a draw.  This
method returns an array to all the winners of a contest.  In
most circumstances this will be a single entry.

=cut

sub strict_winners {
	croak "Useless call to strict_winners in void context" if not defined wantarray;
	return $_[0]->graph->predecessorless_vertices;
}

=head2 rankings

   my @results = $rp->rankings;

This method returns an ordered list of contestents, with the winner in
position 0.  Ties are ignored; if two or more entries are tied they
will be returned adjacent to each other, but in an indeterminate
sequence.  Use L<strict_rankings> if tie detection is required.

=cut

sub rankings {
	my ($this) = @_;

	croak "Useless call to rankings in void context" if not defined wantarray;

	return map { @$_ } $this->strict_rankings;
}

=head2 strict_rankings

  my @results = $rp->strict_rankings;

This method returns an ordered list of lists.  Each element contains
a reference to all contestants at that position.  This will usually
be a single element, but may contain multiple entries in the case
of draws.

=cut

sub strict_rankings {
	my ($this) = @_;

	croak "Useless call to strict_rankings in void context" if not defined wantarray;

	# Take a copy of the graph.  Don't hurt our original.
	my $graph = $this->graph->copy;
	my @rankings;

	# Iteratively find and remove the winners from the graph.

	while (my @contestants = $graph->predecessorless_vertices) {
		push(@rankings, \@contestants);
		foreach my $vertex (@contestants) {
			$graph->delete_vertex($vertex);
		}
	}

	return @rankings;
}

=head2 better_than

  my @higher_ranked = $rp->better_than("Alice");

This function returns all the nodes that I<directly> beat the
given node with significance.  In terms of graphs, these are all
the nodes that have the given node as its destination (ie, its
predecessors).

=cut

sub better_than {
	croak "Useless call to better_than in void context" if not defined wantarray;
	my ($this, $node) = @_;

	return $this->graph->predecessors($node);
}

=head2 worse_than

  my @lower_ranked = $rp->worse_than("Alice");

This function returns all nodes that are I<directly> beaten
by the given node.  In terms of graphs, these are the
nodes successors.

=cut

sub worse_than {
	croak "Useless call to worse_than in void context" if not defined wantarray;
	my ($this, $node) = @_;

	return $this->graph->successors($node);
}

=head2 compile

  $rp->compile;

This method will construct the underlying graph needed to find results.
This method has no effect if the object was created with
C<ordered_input> set to true.

Normally there is no need to call this method by hand.  It is
automatically from any function that needs a compiled graph.

=cut

sub compile {
	my ($this) = @_;

	return unless @{$this->{pairs}};

	# Sort our pairs from largest marjority to smallest majority.
	# In this case, our majority is the distance from the center-point
	# of our range (0.5 by default).

	my @pairs = sort { 
		abs($b->[INDEX_MAJORITY] - HALF_RANGE) <=>
		abs($a->[INDEX_MAJORITY] - HALF_RANGE)
	} @{$this->{pairs}};

	foreach my $pairwise (@pairs) {
		$this->_add(@$pairwise);
	}

	$this->{pairs} = [];
	
	return;
}

=head2 graph

  my $graph = $rp->graph;

Returns the underlying L<Graph> object used.  This isn't a copy of
the object, it I<is> the object, so be careful if you plan on
making changes to it.

=cut

sub graph {
	my ($this) = @_;

	$this->compile;

	return $this->_graph;
}

# This fetches our graph without attempting a compile.  It's required
# for operations such as _add that actually do the work of compiling
# the graph in the first place.

sub _graph {
	return $_[0]->{graph};
}

1;
__END__

=head1 BUGS

Calling any method besides from L<add> will cause the graph to be
compiled, at which point any significant edges become "locked".  Adding
edges after this point will result in them being considered less
significant than any edges present at the time of the compile, regardless
of their majority.

Rankings are obtained by repeatedly removing source nodes from the
graph.  An alternate (but much slower) way of producing rankings
would be to recompile the entire graph without those nodes entirely.
In some circumstances this may produce different results for the
runner-ups.

This is not a definitive list of bugs.

=head1 SEE ALSO

The L<Graph> module.

L<http://en.wikipedia.org/wiki/Ranked_Pairs> - Wikipedia article on Ranked
Pairs.

L<http://condorcet.org/rp/> - Ranked Pairs discussion at Condorcet.org

L<http://en.wikipedia.org/wiki/Condorcet_method> - Description of
condorcet methods.

=head1 AUTHOR

Paul Fenwick, E<lt>pjf@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Paul Fenwick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
