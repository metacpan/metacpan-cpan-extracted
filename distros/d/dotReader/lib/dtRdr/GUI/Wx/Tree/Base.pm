package dtRdr::GUI::Wx::Tree::Base;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Wx;
use Wx::Event;
use base 'WxPerl::TreeCtrlMapped';

use dtRdr::Logger;

use Class::Accessor::Classy;
ro qw(
  main_frame
  bv_manager
);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::Tree::Base - base class for sidebar trees

=head1 SYNOPSIS

=cut


=head2 init

  $tree->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;
  $self->{main_frame} = $frame;
  my @attributes = qw(
    bv_manager
  );
  foreach my $attrib (@attributes) {
    $self->{$attrib} = $frame->$attrib;
  }

  # free events!  get 'em while they're hot
  if($self->can('item_activated')) {
    Wx::Event::EVT_TREE_ITEM_ACTIVATED(
      $self, $self, sub { $_[0]->item_activated($_[1]);}
    );
  }
  # and the right-click
  if($self->can('show_context_menu')) {
    Wx::Event::EVT_TREE_ITEM_MENU(
      $self, $self, sub { $_[0]->show_context_menu($_[1]) }
    );
  }

  # this is not there
  0 and Wx::Event::EVT_TREE_ITEM_GETTOOLTIP($self, sub {
    my ($s, $e) = @_;
    $e->SetToolTip('Foo');
  });
  0 and WARN "default indent: ", $self->GetIndent;
  $self->SetIndent(7);
} # end subroutine init definition
########################################################################

=head2 select_item

Select the tree item for a given $id.

  $tree->select_item($id)

The id is probably the id of whatever your widget associated with each
tree item.

=cut

sub select_item {
  my $self = shift;
  my ($id) = (@_);
  $id = $self->id_or_id($id);

  if(defined(my $item = $self->get_item($id))) {
    $self->SelectItem($item, 'true');
  }
} # end subroutine select_item definition
########################################################################

=head1 Convenience

=head2 id_or_id

Checks whether $id is a scalar or an object which can('id') and return
the id.

  $id = $self->id_or_id($id);

=cut

sub id_or_id {
  my $self = shift;
  my ($id) = (@_);
  if(ref($id)) { # auto-grab it
    eval { $id->can('id') } or
      croak('id_or_id($id) -- $id must be a scalar or object');
    $id = $id->id;
  }
  return($id);
} # end subroutine id_or_id definition
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
