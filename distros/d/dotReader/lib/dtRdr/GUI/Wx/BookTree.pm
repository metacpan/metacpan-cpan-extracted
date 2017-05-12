package dtRdr::GUI::Wx::BookTree;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use base 'dtRdr::GUI::Wx::Tree::Base';

=head1 NAME

dtRdr::GUI::Wx::BookTree - treectrl subclass

=head1 SYNOPSIS

=cut

=head1 Methods

=head2 populate

Fill in the TOC widget with all the nodes from the book.

  $tree->populate($Book)

=cut

sub populate {
  my $self = shift;
  my ($book) = @_;

  $self->DeleteAllItems;
  my $toc = $book->toc;
  my $root = $self->AddRoot($toc->get_title, -1, -1,
    [$toc->id, $toc]);
  $self->_add_sublevel($root, $book, $toc);
  $self->Expand($root);
} # populate
########################################################################

=head2 _add_sublevel

  $tree->_add_sublevel($TreeCtrl_parent, $Book, $TOC_root)

=cut

sub _add_sublevel {
  my $self = shift;
  my ($parent, $book, $toc_root) = @_;

  0 and warn 'add_to_sublevel';
  my @toc = $toc_root->children;
  foreach my $toc_entry (@toc) {
    # XXX the below is a bug (?) on test_packages/ThoutPackageDoc.jar
    if($toc_entry->visible) {
      my $node = $self->AppendItem(
          $parent, $toc_entry->get_title, -1, -1,
          [$toc_entry->id, $toc_entry]
        );
      $self->_add_sublevel($node, $book, $toc_entry);
    }
    else {
      $self->_add_sublevel($parent, $book, $toc_entry);
    }
  }
} # _add_sublevel
########################################################################

=head1 Events

=head2 item_activated

  $self->item_activated($event);

=cut

sub item_activated {
  my $self = shift;
  my ($event) = @_;

  my $item = $event->GetItem;
  my $id = $self->get_id($item);
  return unless defined $id;

  $self->bv_manager->book_view->render_node_by_id($id);
} # end subroutine item_activated definition
########################################################################

=head1 State

=head2 capture_state

Capture the widget's current state in the $state object.

  my $state = $tree->capture_state;

=cut

sub capture_state {
  my $self = shift;

  my $state = {};

  die "unfinished";
  return($state);
} # end subroutine capture_state definition
########################################################################

=head2 restore_state

Restore the widget's state from the $state object.

  $tree->restore_state($state);

=cut

sub restore_state {
  my $self = shift;
  my ($state) = @_;

  die "unfinished";
} # end subroutine restore_state definition
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

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
