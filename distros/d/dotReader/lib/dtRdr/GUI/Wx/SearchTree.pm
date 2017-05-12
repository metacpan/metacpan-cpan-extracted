package dtRdr::GUI::Wx::SearchTree;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use base 'dtRdr::GUI::Wx::Tree::Base';

use dtRdr::Logger;

=head1 NAME

dtRdr::GUI::Wx::SearchTree - display search results as a tree

=head1 SYNOPSIS

=cut

=head1 Methods

=head2 book_root

Create a root for the book.

  $tree->book_root($book);

When we're displaying multiple books, this will not be the root of the
tree?

=cut

sub book_root {
  my $self = shift;

  my ($book) = @_;

  my $toc = $book->toc;
  my $id = $toc->id; # TODO that isn't enough
  my $root = $self->AddRoot(
    $toc->get_title, -1, -1,
    [$id, $toc]
  );
  $self->Expand($root);
} # end subroutine book_root definition
########################################################################

=head2 want_item

  $item = $tree->want_item($node);

=cut

sub want_item {
  my $self = shift;
  my ($node) = @_;
  if(my $item = $self->get_item($node->id)) {
    # he's already got one, see
    return($item);
  }

                      # How do I hate Win32, let me count the ways...
                      my $scroll;
                      if($^O eq 'MSWin32') { # BAH!
                        $scroll= $self->GetScrollPos(Wx::wxVERTICAL());
                        0 and WARN "scroll at $scroll",
                        $self->Freeze;
                      }            # more fun below ------------------v

  my $parent = $self->parent_item($node);

  # XXX assumes siblings have arrived in order!
  my $item = $self->append_item($parent, $node);

  $self->Expand($self->GetRootItem);
  $self->Expand($parent);

                      # ... one Win32, two Win32, three Win32...
                      if($^O eq 'MSWin32') {
                        $self->SetScrollPos(Wx::wxVERTICAL(), $scroll);
                        0 and WARN "scroll at ",
                          $self->GetScrollPos(Wx::wxVERTICAL());
                        $self->Thaw;
                      }

  return($item);
} # end subroutine want_item definition
########################################################################

=head2 parent_item

Get or create the tree down to (not including) the given node.

  my $parent = $tree->parent_item($node);

=cut

sub parent_item {
  my $self = shift;
  my ($node) = @_;
  my (@ancestors) = $node->ancestors;
  if(my $parent = $self->get_item($ancestors[0])) {
    return($parent);
  }
  # start at root and go down?
  @ancestors = reverse(@ancestors);
  my $root = $self->get_item(shift(@ancestors)->id);
  foreach my $entry (@ancestors) {
    $entry->visible or next; # invisible tree speed-bump
    if(my $have_item = $self->get_item($entry->id)) {
      # he's already got one, see
      $root = $have_item;
      # now go away or I shall taunt you another time
      next;
    }
    $root = $self->append_item($root, $entry);
  }
  return($root);
} # end subroutine parent_item definition
########################################################################

=head2 append_item

Append a TOC node to the tree.

  $tree_item = $tree->append_item($parent_item, $toc);

=cut

sub append_item {
  my $self = shift;
  my ($parent, $node) = @_;
  my $id = $node->id;
  my $item = $self->AppendItem(
    $parent, $node->get_title, -1, -1, [$id, $node]
  );
  $self->Expand($parent);
  return($item);
} # end subroutine append_item definition
########################################################################

=head1 Event Handlers

=head2 show_context_menu

  $self->show_context_menu($evt);

=cut

sub show_context_menu {
  my $self = shift;
  my ($evt) = @_;
  my $item = $self->GetSelection;
  $item->IsOk or die "what?";
  my $node = $self->get_data($item);
  $self->GetParent->show_context_menu($node, $evt->GetPoint);
} # end subroutine show_context_menu definition
########################################################################

=head2 item_activated

  $tree->item_activated($event);

=cut

sub item_activated {
  my $self = shift;
  my ($event) = @_;

  my $node = $self->get_data($event->GetItem);
  $node or die "now what? ($event)";

  $self->GetParent->goto_item($node);
} # end subroutine item_activated definition
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
