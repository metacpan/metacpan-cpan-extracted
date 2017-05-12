#
# This file is part of Tree-BK
#
# This software is copyright (c) 2014 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Tree::BK;
$Tree::BK::VERSION = '0.02';
use strict;
use warnings;
use Text::Levenshtein::XS qw(distance);
use Carp;

# ABSTRACT: Structure for efficient fuzzy matching


sub new {
	my ($class, $metric) = @_;
	if(defined $metric){
		if((ref $metric) ne 'CODE'){
			croak 'argument to new() should be ' .
				'a code reference implementing a metric';
		}
	}else{
		$metric = \&Text::Levenshtein::XS::distance;
	}
	my $tree = bless {
		metric => $metric,
		root => undef,
		size => 0,
	}, $class;
	return $tree;
}


sub insert {
	my ($self, $object) = @_;
	if(!defined $self->{root}){
		$self->{root} = { object=>$object };
		$self->{size}++;
		return $object;
	}

	my $current = $self->{root};
	my $dist = $self->{metric}->($current->{object}, $object);
	while(exists $current->{$dist}){
		# object was already in the tree
		if($dist == 0){
			return;
		}
		$current = $current->{$dist};
		$dist = $self->{metric}->($current->{object}, $object);
	}
	# prevent adding the root node multiple times
	if($dist == 0){
		return;
	}
	$current->{$dist} = {object => $object};
	$self->{size}++;
	return $object;
}

sub insert_all {
	my ($self, @objects) = @_;
	if(@objects < 1){
		croak 'Must pass at least one object to insert_all method';
	}
	my $size_before = $self->size;
	$self->insert($_) for @objects;
	return $self->size - $size_before;
}

sub find {
	my ($self, $target, $threshold) = @_;
	my @return;
	$self->_find($self->{root}, \@return, $target, $threshold);
	return \@return;
}

sub _find {
	my ($self, $node, $current_list, $target, $threshold) = @_;
	my $distance = $self->{metric}->($node->{object}, $target);
	my $min_dist = $distance - $threshold;
	my $max_dist = $distance + $threshold;
	if($distance <= $threshold){
		push @$current_list, $node->{object};
	}
	# recursively search the children where nodes with the threshold
	# distance might reside
	for(keys %$node){
		next if $_ eq 'object';
		next unless $_ >= $min_dist && $_ <= $max_dist;
		$self->_find($node->{$_}, $current_list, $target, $threshold);
	}
}

sub size {
	my ($self) = @_;
	return $self->{size};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::BK - Structure for efficient fuzzy matching

=head1 VERSION

version 0.02

=head1 SYNOPSIS

	use Tree::BK;
	my $tree = Tree::BK->new();
	$tree->insert(qw(cuba cubic cube cubby thing foo bar));
	$tree->find('cube', 1); # cuba, cube
	$tree->find('cube', 2); # cuba, cubic, cube, cubby

=head1 DESCRIPTION

The Burkhard-Keller, or BK tree, is a structure for efficiently
performing fuzzy matching. By default, this module assumes string
input and uses L<Text::Levenshtein::XS/distance> to compare items
and build the tree. However, a subroutine giving the distance
between two tree members may be provided, making this structure
more generally usable.

=head1 METHODS

=head2 C<new>

 Tree::BK->new(\&metric);

Creates a new instance of Tree::BK. A metric may be provided as an
argument. It should be a subroutine which takes two tree members
as arguments and returns a positive integer indicating the distance
between them. If no metric is provided, then the tree members are
assumed to be strings, and L<Text::Levenshtein::XS/distance> is used
as the metric.

=head2 C<insert>

Inserts an object into the tree. Returns nothing if the object
was already in the tree, or the object if it was added to the tree.

=head2 C<insert_all>

Inserts all of the input objects into the tree. Returns the number
of objects that were added to the tree (i.e. the number of objects
that weren't already present in the tree).

=head2 C<find>

 $tree->find($target, $distance)

Returns an array ref containing all of the objects in the tree
which are at most C<$distance> distance away from C<$target>.

=head2 C<size>

Returns the number of objects currently stored in the tree.

=head1 SEE ALSO

These sites explain the concept of a BK tree pretty well:

=over

=item

L<http://nullwords.wordpress.com/2013/03/13/the-bk-tree-a-data-structure-for-spell-checking/>

=item

L<http://blog.notdot.net/2007/4/Damn-Cool-Algorithms-Part-1-BK-Trees>

=back

=head1 AUTHOR

Nathan Glenn <nglenn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
