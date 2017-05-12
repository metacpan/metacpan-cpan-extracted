package WxPerl::TreeCtrlMapped;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Wx;
use base 'Wx::TreeCtrl';

=head1 NAME

WxPerl::TreeCtrlMapped - a more reasonably perlish wxTreeCtrl

=head1 ABOUT

I want a better TreeCtrl

Troubles with wxTreeCtrl:
  o data is ad-hoc nested in TreeCtrl using TreeItemData
  o no random-access to tree without mapping id => TreeItemId
  o no reverse-lookup for id without putting it in TreeItemData

So, we want get_id($item), get_item($id)

And, a way to store a single object as the data (that's not incompatible
with the id mapping.)  If I'm going to store the id and an object, I
would have to say Wx::TreeItemData->new({id => $id, object => $object),
which is just too much given the $tree->GetPlData()->{object} calls that
would always be following it around.

  get_data($id|$item)
  set_data($id|$item, $data)

=head1 TODO

Probably some more convenient get_children() and such methods.

Maybe overriding the Wx::TreeItemId to allow it to have a data() method,
but this could get somewhat tangled WRT events.

=cut

=head1 Overrides

In each of these methods, the TreeItemData parameter in the base class
is replaced with a scalar $id, or an array [$id, $object].

$object can be whatever you want it to be.  It will be returned when you
call get_data().

=head2 AddRoot

  $tree->AddRoot($text, $image, $selimage, $id_or_array);

=cut

sub AddRoot {
  my $self = shift;
  my (@args) = @_;
  $args[3] = $self->_new_data($args[3]);
  return($self->_map_new($self->SUPER::AddRoot(@args)));
} # end subroutine AddRoot definition
########################################################################

=head2 AppendItem

  $tree->AppendItem($parent, $text, $image, $selimage, $id_or_array);

=cut

sub AppendItem {
  my $self = shift;
  my (@args) = @_;
  $args[4] = $self->_new_data($args[4]);
  return($self->_map_new($self->SUPER::AppendItem(@args)));
} # end subroutine AppendItem definition
########################################################################

=head2 InsertItem

  $tree->InsertItem($parent, $prev, $text, $img, $selimg, $id_or_array);

=cut

sub InsertItem {
  my $self = shift;
  my (@args) = @_;
  $args[4] = $self->_new_data($args[4]);
  return($self->_map_new($self->SUPER::InsertItem(@args)));
} # end subroutine InsertItem definition
########################################################################

=head2 PrependItem

  $tree->PrependItem($parent, $text, $image, $selImage, $id_or_array);

=cut

sub PrependItem {
  my $self = shift;
  my (@args) = @_;
  $args[4] = $self->_new_data($args[4]);
  return($self->_map_new($self->SUPER::PrependItem(@args)));
} # end subroutine PrependItem definition
########################################################################

=head1 Cleanup

These are overridden to cleanup the mappings.

=head2 Delete

  $tree->Delete($item);

=cut

sub Delete {
  my $self = shift;
  my ($item) = @_;

  my $map = $self->{_item_map};
  %$map or die "that's going to hurt";

  my $mapped_id = $self->get_id($item);
  $self->SUPER::Delete($item);
  # cleanup after (in case there are events)
  delete($map->{$mapped_id});
} # end subroutine Delete definition
########################################################################

=head2 DeleteAllItems

  $tree->DeleteAllItems;

=cut

sub DeleteAllItems {
  my $self = shift;
  $self->SUPER::DeleteAllItems;
  $self->_clear; # clear after super in case there are events
} # end subroutine DeleteAllItems definition
########################################################################

=head2 DeleteChildren

  $tree->DeleteChildren($item);

=cut

sub DeleteChildren {
  my $self = shift;
  my ($item) = @_;
  die "not working yet";

} # end subroutine DeleteChildren definition
########################################################################

=head1 Internals

=head2 _new_data

  my $data = $self->_new_data($id);

Or:

  my $data = $self->_new_data([$id, $object]);

=cut

sub _new_data {
  my $self = shift;
  my ($thing) = @_;

  my ($id, $object) = ($thing);
  if(my $ref = ref($thing)) {
    ($ref eq 'ARRAY') or
      croak('must be scalar or [$id, $object] array ref');
    ($id, $object) = @$thing;
  }

  return(Wx::TreeItemData->new({id => $id, object => $object}));
} # end subroutine _new_data definition
########################################################################

=head2 _map_new

  my $item = $self->_map_new($item);

=cut

sub _map_new {
  my $self = shift;
  my ($item) = @_;
  my $id = $self->get_id($item);
  $self->_map_item($id, $item);
  return($item);
} # end subroutine _map_new definition
########################################################################

=head2 _map_item

  $self->_map_item($id, $item);

=cut

sub _map_item {
  my $self = shift;
  my ($id, $item) = @_;

  $self->{_item_map} ||= {};
  my $map = $self->{_item_map};
  exists($map->{$id}) and croak("attempt to remap id: $id");
  $map->{$id} = $item;
} # end subroutine _map_item definition
########################################################################

=head2 _clear

  $self->_clear;

=cut

sub _clear {
  my $self = shift;
  $self->{_item_map} = {};
} # end subroutine _clear definition
########################################################################

=head1 Lookups

=head2 get_item

Get the item for a given $id.

  my $item = $self->get_item($id);

=cut

sub get_item {
  my $self = shift;
  my ($id) = @_;

  my $map = $self->{_item_map};
  $map or return();

  return($map->{$id});
} # end subroutine get_item definition
########################################################################

=head2 get_id

  my $id = $self->get_id($item);

=cut

sub get_id {
  my $self = shift;
  my ($item) = @_;

  my $data = $self->GetPlData($item);
  $data or croak("no data for $item");
  return($data->{id});
} # end subroutine get_id definition
########################################################################

=head1 Data

=head2 get_data

  $self->get_data($id|$item);

=cut

sub get_data {
  my $self = shift;
  my ($item) = @_;

  unless(ref($item)) { # it is an id
    $item = $self->get_item($item);
  }
  my $data = $self->GetPlData($item);
  $data or croak("no data for $item");
  return($data->{object});
} # end subroutine get_data definition
########################################################################

=head2 set_data

  $self->set_data($id|$item, $data);

=cut

sub set_data {
  my $self = shift;
  my ($item, $object) = @_;

  my $id;
  unless(ref($item)) { # it is an id
    $id = $item;
    $item = $self->get_item($item);
  }
  else {
    $id = $self->get_id($item);
  }

  $self->SetItemData(
    $item,
    Wx::TreeItemData->new({id => $id, object => $object})
  );
} # end subroutine set_data definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
