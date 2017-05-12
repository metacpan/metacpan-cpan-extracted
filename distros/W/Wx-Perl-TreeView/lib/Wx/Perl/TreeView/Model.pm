package Wx::Perl::TreeView::Model;

=head1 NAME

Wx::Perl::TreeView::Model - virtual tree control model class

=head1 DESCRIPTION

An abstract base class for all models.

=head1 METHODS

=cut

use strict;

=head2 get_root

  my( $cookie, $string, $image, $data ) = $model->get_root;

C<$cookie> is an opaque identifier specific to the model
implementation that can be used to access model nodes.
C<$string>, C<$image> and C<$data> are the item's label, image and
client data (the latter two are optional).

=cut

sub get_root { my( $self ) = @_; die 'Implement me'; }

=head2 get_child_count

  my $count = $model->get_child_count( $cookie );

Return the numer of childrens of a given node.

=cut

sub get_child_count { my( $self, $cookie ) = @_; die 'Implement me'; }

=head2 get_child

  my( $cookie, $string, $image, $data ) = $model->get_child( $cookie, $index );

Return the n-th child of the given node. See C<get_root> for the return
values.

=cut

sub get_child { my( $self, $cookie, $index ) = @_; die 'Implement me'; }

=head2 has_children

  my $has_children = $model->has_children( $cookie );

Return true if the given item has childrens.  The default implementation
uses C<get_child_count> return value.

=cut

sub has_children { $_[0]->get_child_count( $_[1] ) != 0 }

1;
