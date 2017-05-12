
package Tree::Simple::Manager::Index;

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = '0.04';
    
use Tree::Simple::Manager::Exceptions;    
    
sub new {
    my ($_class, $tree) = @_;
    my $class = ref($_class) || $_class;
    my $index = {};
    bless($index, $class);
    $index->_init($tree);
    return $index;
}

sub _init {
    my ($self, $tree) = @_;
    (blessed($tree) && $tree->isa("Tree::Simple")) 
        || throw Tree::Simple::Manager::InsufficientArguments;
    # add our root
    $self->{root_tree} = $tree;
    $self->{index}     = {};
    # then add all its children on down
    $self->indexTree();
}

sub indexTree {
    my ($self) = @_;
    $self->{root_tree}->traverse(sub {
        my ($tree) = @_;
        (!exists $self->{index}->{$tree->getUID()}) 
            || throw Tree::Simple::Manager::IllegalOperation "tree (" . $tree->getUID() . ") already exists in the index, cannot add a duplicate";        
        $self->{index}->{$tree->getUID()} = $tree;
    });
}

sub getRootTree { (shift)->{root_tree} }
 
sub getIndexKeys {
    my ($self) = @_;
    my @keys = keys %{$self->{index}};
    return wantarray ? @keys : \@keys;
}

sub getTreeByID {
    my ($self, $id) = @_;
    (exists $self->{index}->{$id}) 
        || throw Tree::Simple::Manager::KeyDoesNotExist "tree ($id) does not exist in the index";        
    return $self->{index}->{$id};
}

sub hasTreeAtID {
    my ($self, $id) = @_;
    exists $self->{index}->{$id} ? 1 : 0  
}

1;

__END__

=pod

=head1 NAME

Tree::Simple::Manager::Index - A class for quick-access indexing for Tree::Simple hierarchies

=head1 SYNOPSIS

  use Tree::Simple::Manager::Index;
  
  my $index = Tree::Simple::Manager::Index->new($tree_hierarchy);  
  my $node_deep_in_the_tree = $index->getTreeByID(100134);

=head1 DESCRIPTION

This module will index a Tree::Simple hierarchy so that node's can be quickly accessed without needing to search the entire heirarchy. It currently will index the Tree::Simple nodes by their UID property. Plans for allowing other means of indexing are in the future.

=head1 METHODS

=over 4

=item B<new ($tree)>

Given a C<$tree> it will index all it's nodes by their UID values.

=item B<indexTree>

This will take the root tree (the C<$tree> arguments in C<new>) and index it. This method can be overridden by a subclass to provide custom indexing functionality. See the L<SUBCLASSING> section below.

=item B<getIndexKeys>

This will return a list of all the index keys. 

=item B<getRootTree>

This will return the root of the indexed tree.

=item B<getTreeByID ($id)>

Given an C<$id> this will return the tree associated with it. If no tree is associated with it, an exeception will be thrown.

=item B<hasTreeAtID ($id)>

Returns a boolean if there is a tree associated with that C<$id>.

=back

=head1 SUBCLASSING

This module will index a Tree::Simple hierarchy using the UID property of each tree node (fetched with the C<getUID> method of Tree::Simple). This works well with the Tree::Simple::Manager's default tree file parser filter, which expects a tree file format which supplies an id field. It is obvious that this approach may not be useful in all cases, so I have built this module too easily allow for subclassing and customization of the indexing process. 

You will need to override the C<indexTree> method. The root tree is accessible by the C<getRootTree> method, and the index is a hash reference available as a public field C<$self-E<gt>{index}>. How you choose to construct the index from here is up to you. Here are a couple of things to keep in mind though.

=over

=item Duplicate index keys

We throw an exception in the default indexer if we notice a duplicate key being created. It is the responsibility of the subclass author to check.

=item 

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the L<Tree::Simple::Manager> documentation for more details.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

