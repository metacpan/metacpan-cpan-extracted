package dtRdr::GUI::Wx::Tree::AnnoBase;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use Scope::Guard;

use base 'dtRdr::GUI::Wx::Tree::Base';

use Class::Accessor::Classy;
ro 'context_menu';
ro 'menu_item_goto';
ro 'menu_item_delete';
no  Class::Accessor::Classy;

use constant DISABLED_ITEMS => 'delete';

use Wx qw(
  wxITEM_NORMAL
  wxCANCEL
  wxOK
  wxID_OK
  wxID_YES
  wxYES_NO
  wxYES_DEFAULT
);

use Wx::Event;

use dtRdr::Logger;

use dtRdr::GUI::Wx::Utils qw(_accel);

=head1 NAME

dtRdr::GUI::Wx::Tree::AnnoBase - base class for sidebar annotation trees

=head1 SYNOPSIS

=cut


=head1 Methods

=head2 init

  $tree->init($frame);

=cut

sub init {
  my $self = shift;

  $self->SUPER::init(@_);
  $self->setup_menu;

  $self->SetAcceleratorTable(Wx::AcceleratorTable->new(
    map({$self->_accel(@$_)}
      ['DELETE', 'menu_delete'],
    )
  ));

} # end subroutine init definition
########################################################################

=head2 setup_menu

Generate the context menu.

  $self->setup_menu;

=cut

sub setup_menu {
  my $self = shift;

  $self->append_menu(@$_) for(
    ['goto', 'Jump To', '',],
    ['delete', 'Delete', '',],
  );

} # end subroutine setup_menu definition
########################################################################

=head2 append_menu

  $self->append_menu($name, $label, $help);

=cut

sub append_menu {
  my $self = shift;
  my ($name, $label, $help) = @_;
  $help = '' unless(defined($help));

  my $cmenu = $self->{context_menu} ||= Wx::Menu->new('', 0);

  # TODO put a tag in to catch this?
  #$cmenu->AppendSeparator;
  my $mitem = $self->{"menu_item_$name"} =
    $cmenu->Append( -1, $label, $help, wxITEM_NORMAL);
  my $method = 'menu_' . $name;
  Wx::Event::EVT_MENU($self, $mitem, sub { $_[0]->$method($_[1]) });
  return($mitem);
} # end subroutine append_menu definition
########################################################################

=head2 show_context_menu

Displays the right click context menu for the tree control.

  $tree->show_context_menu($event);

=cut

sub show_context_menu {
  my $self = shift;
  my ($evt) = (@_);

  my $ferret = $self->disable_menu_items($evt);

  $self->PopupMenu($self->context_menu, $evt->GetPoint);
} # end subroutine show_context_menu definition
########################################################################

=head2 disable_menu_items

Temporarily disables the appropriate menu items, restoring them when the
ferret gets loose.

  my $ferret = $self->disable_menu_items($evt);

Public annotations owned by other users will have the results of
$self->DISABLED_ITEMS() disabled.

Example: multiple items selected disables goto.

=cut

sub disable_menu_items {
  my $self = shift;
  my ($evt) = @_;

  # I guess just use GetSelections?
  # my @items = $self->event_or_selection_items($evt);
  my @items = $self->GetSelections;
  @items = $evt->GetItem unless(@items);
  
  my @disable;
  if(@items == 1) {
    my $anno = $self->get_data($items[0]);
    unless($anno->is_mine) {
      @disable = $self->DISABLED_ITEMS;
    }
  }
  else {
    @disable = qw(goto);
  }

  $self->_enables(0, @disable);

  return(Scope::Guard->new(sub { $self->_enables(1, @disable); }));
} # end subroutine disable_menu_items definition
########################################################################

=head2 _enables

  $self->_enables($bool, @shortlist);

=cut

sub _enables {
  my $self = shift;
  my ($bool, @list) = @_;

  my $menu = $self->context_menu;
  @list = map({'menu_item_' . $_} @list);

  foreach my $name (@list) {
    $menu->Enable($self->$name->GetId, $bool);
  }
} # end subroutine _enables definition
########################################################################

=head1 Menu Events

=head2 menu_delete

  $self->menu_delete($event);

=cut

sub menu_delete {
  my $self = shift;
  my ($event) = @_;

  my @items = $self->GetSelections;
  @items or return;
  my $count = scalar(@items);
  if($count > 1) { # TODO & maybe eval{$event->isa('Wx::CommandEvent')}
    my $dialog = Wx::MessageDialog->new(
      $self,
      'Are you sure you want to delete ' .
        (($count > 1) ? "the $count selected " : 'this ') .
        $self->anno_type . (($count > 1) ? 's' : '') . '?',
      'Confirm Delete',
      wxYES_NO|wxYES_DEFAULT
    );
    return unless(wxID_YES == $dialog->ShowModal);
  }

  # TODO the actual delete should talk to the BVM?
  foreach my $item (@items) {
    my $anno = $self->get_data($item);
    unless($anno->is_mine) {
      # TODO something like "delete it anyway", or rather "ignore it"
      $self->main_frame->error(
        join(' ', 'The', $anno->ANNOTATION_TYPE, '"'.$anno->title.'"',
        'does not belong to you.')
      );
      next;
    }
    my $delete_this = 'delete_' . $self->anno_type;
    $anno->book->$delete_this($anno);
  }
} # end subroutine menu_delete definition
########################################################################

=head2 menu_goto

  $self->menu_goto($event);

=for podcoverage_private item_activated

Is also the default event on double-click/enter.

=cut

use Method::Alias (item_activated => 'menu_goto');
sub menu_goto {
  my $self = shift;
  my ($event) = @_;

  my ($item, @items) = $self->event_or_selection_items($event);
  defined($item) or return;
  if(@items) {
    croak('cannot goto more than one annotation');
    return;
  }

  my $anno = $self->get_data($item);
  $anno or die "no annotation at that item";
  # XXX we should have our very own bv
  my $bv = $self->bv_manager->book_view;
  $bv->jump_to($anno);
  $bv->hw->SetFocus;
} # end subroutine menu_goto definition
########################################################################

=head2 event_or_selection_items

  my @items = $tree->event_or_selection_items($event);

=cut

sub event_or_selection_items {
  my $self = shift;
  my ($event) = @_;

  if($event and eval{$event->isa('Wx::TreeEvent')}) {
    my $item = $event->GetItem;
    # HUH? Win32 messes up on Enter here?
    unless($item->IsOk) {
      ($^O eq 'MSWin32') or die('tell me about this');
      #L->info("welcome to windows");
      return($self->GetSelections);
    }
    return($item);
  }
  else {
    return($self->GetSelections);
  }
} # end subroutine event_or_selection_items definition
########################################################################

=head1 The Tree

=head2 populate

Fill in the widget with all the annotations for a book.

  $tree->populate($book);

=cut

sub populate {
  my $self = shift;
  my ($book) = @_;

  0 and WARN 'populate';
  $self->DeleteAllItems;

  my @anno = $self->fetch_annotations($book);

  my $root = $self->mk_root;

  # and add them all
  $self->add_item($_) for(@anno);
} # populate
########################################################################

=head2 fetch_annotations

  my @anno = $self->fetch_annotations($book);

=cut

sub fetch_annotations {
  my $self = shift;
  my ($book) = @_;

  my $toc = $book->toc;

  my $fetch_method = 'local_' . $self->anno_type . 's';
  # Don't forget I am not my own descendant
  map({$book->$fetch_method($_)} $toc, $toc->descendants);
} # end subroutine fetch_annotations definition
########################################################################

=head2 mk_root

  $root = $self->mk_root;

=cut

sub mk_root {
  my $self = shift;
  return($self->AddRoot($self->anno_type, -1, -1, 'root'));
} # end subroutine mk_root definition
########################################################################


=head2 add_item

Add an annotation to the tree

  $tree->add_item($anno);

=cut

sub add_item {
  my $self = shift;
  my ($anno) = @_;
  my $root = $self->GetRootItem || $self->mk_root;
  $self->Expand($root); # needed if we show the root node

  # check whether we're creating the first ever
  my ($had) = $self->GetFirstChild($root);

  # make a title;
  my $title = $anno->title;
  $title = 'ID: ' . $anno->id unless(defined($title));

  my $node =
    $self->AppendItem($root, $title, -1, -1, [$anno->id, $anno]);

  # we need to have something selected because we have no root
  $self->SelectItem($node) unless($had);
} # end subroutine add_item definition
########################################################################

=head2 delete_item

  $tree->delete_item($anno);

=cut

sub delete_item {
  my $self = shift;
  my ($id) = @_;
  $id = $self->id_or_id($id);
  $self->Delete($self->get_item($id));
} # end subroutine delete_item definition
########################################################################

=head2 item_changed

  $tree->item_changed($anno);

=cut

sub item_changed {
  my $self = shift;
  my ($anno) = @_;
  my $id = $anno->id;
  if(defined(my $item = $self->get_item($id))) {
    # update the title, etc
    my $title = $anno->title;
    $title = 'ID: ' . $id unless(defined($title));
    $self->SetItemText($item, $title);
  }
  else {
    RL('#gui')->error('tree in inconsistent state');
    # should maybe die now
  }
} # end subroutine item_changed definition
########################################################################


=head1 TODO: State

  my $state = $tree->capture_state;

  $tree->restore_state($state);

=cut




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
