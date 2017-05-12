package dtRdr::GUI::Wx::NoteTree;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use Class::Accessor::Classy;
ro 'menu_item_show';
ro 'menu_item_edit';
no  Class::Accessor::Classy;

sub DISABLED_ITEMS { return(shift->SUPER::DISABLED_ITEMS(), 'edit'); }

use base 'dtRdr::GUI::Wx::Tree::AnnoBase';

use constant { anno_type => 'note' };

use dtRdr::Logger;

=head1 NAME

dtRdr::GUI::Wx::NoteTree - treectrl subclass

=head1 SYNOPSIS

=cut

=head2 setup_menu

Overrides base class to change doubleclick and add options.

  $self->setup_menu;

=cut

sub setup_menu {
  my $self = shift;
  $self->SUPER::setup_menu;
  $self->append_menu(@$_) for(
    ['show', 'Show'],
    ['edit', 'Edit'],
  );
  Wx::Event::EVT_TREE_ITEM_ACTIVATED($self, $self,
    sub {$_[0]->item_activated($_[1])}
  );

} # end subroutine setup_menu definition
########################################################################

=head2 item_activated

  $tree->item_activated($event);

=cut

sub item_activated {
  my $self = shift;
  my ($event) = @_;
  $self->menu_goto($event);
  my $item = $event->GetItem;
  my $anno = $self->get_data($item);
  $self->bv_manager->show_note($anno);
} # end subroutine item_activated definition
########################################################################

=head2 menu_show

  $tree->menu_show($event);

=cut

sub menu_show {
  my $self = shift;
  my ($event) = @_;

  my ($item, @items) = $self->event_or_selection_items($event);
  # TODO need a multi-note viewer
  @items and WARN("cannot show multiple notes yet");
  my $anno = $self->get_data($item);
  $self->bv_manager->show_note($anno);
} # end subroutine menu_show definition
########################################################################

=head2 menu_edit

  $tree->menu_edit($event);

=cut

sub menu_edit {
  my $self = shift;
  my ($event) = @_;

  my @items = $self->event_or_selection_items($event);
  foreach my $item (@items) {
    my $anno = $self->get_data($item);
    $self->bv_manager->edit_note($anno);
  }
} # end subroutine menu_edit definition
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
