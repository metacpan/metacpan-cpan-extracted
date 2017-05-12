package dtRdr::GUI::Wx::LibraryTree;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use dtRdr;
use dtRdr::Logger;

use Wx;
use Wx::Event;
use base 'dtRdr::GUI::Wx::Tree::Base';

=head1 NAME

dtRdr::GUI::Wx::LibraryTree - the sidebar libraries tree

=head1 SYNOPSIS

=cut

=head1 Constructor

=head2 new

  dtRdr::GUI::Wx::LibraryTree->new($parent, blahblahblah);

=cut

sub new {
  my $class = shift;
  my ($parent, @args) = @_;

  my $no_root = 1;
  if($no_root) { # do without a root
    $args[3] = $args[3]^Wx::wxTR_HIDE_ROOT();
  }
  my $self = $class->SUPER::new($parent, @args);

  return($self);
} # end subroutine new definition
########################################################################

=head1 Methods

=head2 populate

  $tree->populate;

=cut

sub populate {
  my $self = shift;

  # hmm. config is like a LibraryCard?
  my @libraries = dtRdr->user->libraries;
  #warn "Got ", scalar(@libraries), " libraries";
  my $toplevel = $self->AddRoot("My Libraries", -1, -1, 'root');
  foreach my $library (@libraries) {
    my $id = "$library";
    my $root = $self->AppendItem($toplevel,
      # TODO that should be $library->name
      $library->get_info('name'), -1, -1, [$id, $library]
    );

    foreach my $book_info ($library->get_book_info()) {
      my $title = $book_info->title;
      my $intid = $library . "\0" . $book_info->intid;
      # TODO may need to change library to use intid for books
      $self->AppendItem($root, $title, -1, -1,
        [$intid, $book_info],
      )
    }
    # XXX maybe only expand the first (e.g. default) library
    $self->Expand($root);
  }
  $self->Expand($toplevel);

  if(@libraries) {
    my ($child) = $self->GetFirstChild($toplevel);
    $self->SelectItem($child);
  }

} # end subroutine populate definition
########################################################################

=head2 repopulate

  $tree->repopulate;

=cut

sub repopulate {
  my $self = shift;

  # TODO this may need to be a bit more careful
  $self->DeleteAllItems;
  $self->populate;
} # end subroutine repopulate definition
########################################################################

=head1 Events

=head2 item_activated

  $self->item_activated($event);

=cut

sub item_activated {
  my $self = shift;
  my ($event) = @_;

  my $item = $event->GetItem;
  unless($item->IsOk) {
    # I landed here when trying to fire events manually. --E
    # maybe let this just grab the current selection?
    #$item = $self->GetSelection;
    0 and warn "that might explain something";
  }
  0 and warn "item: $item\n";
  my $data = $self->get_data($item);
  0 and ($data or warn "no data for ",
    $self->GetItemText($item), " sorry");

  if($data->isa('dtRdr::LibraryData::BookInfo')) {
    0 and warn "got a book";
    my $bvm = $self->bv_manager;
    my $book = eval {$self->main_frame->busy(sub {
      $data->library->open_book(intid => $data->intid);
    })} or return $self->main_frame->error("cannot open book -- $@");
    $bvm->open_book($book);
  }
  else {
    # XXX this should check whether it is expanded
    # let the "Enter" key expand an item (XXX maybe a bug on MSWin32)
    # go by whether it has children, not data
    if($self->ItemHasChildren($item)) {
      $self->Expand($item);
      $self->SelectItem($self->GetFirstChild($item));
    }
  }
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
