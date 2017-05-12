package dtRdr::GUI::Wx::Sidebar;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use dtRdr::GUI::Wx::Utils;
use dtRdr::GUI::Wx::LibraryTree;
use dtRdr::GUI::Wx::BookTree;
use dtRdr::GUI::Wx::SearchPane;
use dtRdr::GUI::Wx::NoteTree;
use dtRdr::GUI::Wx::BookmarkTree;
use dtRdr::GUI::Wx::HighlightTree;
use dtRdr::Logger;

use base 'Wx::Panel';
use Wx ();
use Wx::Event;
use WxPerl::ShortCuts;

use dtRdr::Accessor;
dtRdr::Accessor->ro qw(
  libraries
  contents
  search
  notes
  bookmarks
  highlights
  button_libraries
  button_contents
  button_search
  button_notes
  button_bookmarks
  button_highlights
  sizer
  grid_sizer
  adwidget
);
my $set_current_item = dtRdr::Accessor->ro_w('current_item');


=head1 NAME

dtRdr::GUI::Wx::Sidebar - everything in the sidebar

=head1 SYNOPSIS

=cut

=head1 Constructor

=head2 new

  my $sidebar = dtRdr::GUI::Wx::Sidebar->new($parent, blah blah);

=cut

sub new {
  my $class = shift;
  my ($parent, @args) = @_;

  my $self = $class->SUPER::new($parent, @args);

  $self->__create_children;
  $self->__do_layout;
  #$self->__do_properties;

  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Setup

=head2 __create_children

  $self->__create_children;

=cut

sub __create_children {
  my $self = shift;

  # buttons
  foreach my $attrib ($self->core_attribs) {
    my $button_name = 'button_' . $attrib;
    my $button = Wx::BitmapButton->new($self, -1,
      dtRdr::GUI::Wx::Utils->Bitmap("sb_button_$attrib")
    );
    $button->SetToolTipString(ucfirst($attrib));
    Wx::Event::EVT_BUTTON($button, -1, sub {
      $self->select_item($attrib);
    });
    $self->{$button_name} = $button;
  }

  my $tree_style_1 =
    WX"SUNKEN_BORDER" |
    TR"HAS_BUTTONS|NO_LINES|LINES_AT_ROOT|DEFAULT_STYLE";
  # two tree thingies
  $self->{$_->[0]} = $_->[1]->new($self, -1, DefPS, $tree_style_1) for(
    [qw(libraries dtRdr::GUI::Wx::LibraryTree)],
    [qw(contents  dtRdr::GUI::Wx::BookTree)],
  );

  # one of these
  $self->{search} = dtRdr::GUI::Wx::SearchPane->new($self, -1, DefPS);

  my $tree_style_2 = WX"SUNKEN_BORDER"|
    TR"HAS_BUTTONS|NO_LINES|LINES_AT_ROOT|MULTIPLE|HIDE_ROOT";
  # three tree thingies
  $self->{$_->[0]} = $_->[1]->new($self, -1, DefPS, $tree_style_2) for(
    [qw(notes      dtRdr::GUI::Wx::NoteTree)],
    [qw(bookmarks  dtRdr::GUI::Wx::BookmarkTree)],
    [qw(highlights dtRdr::GUI::Wx::HighlightTree)],
  );
} # end subroutine __create_children definition
########################################################################

=head2 __do_layout

  $self->__do_layout;

=cut

sub __do_layout {
  my $self = shift;

  my $sizer = $self->{sizer} = Wx::BoxSizer->new(wV);
  my $grid = $self->{grid_sizer} = Wx::GridSizer->new(1, 6, 0, 0);

  $grid->Add($self->$_, 0, Ams, 0)
    for(map({'button_' . $_} $self->core_attribs));
  $sizer->Add($grid, 0, Ams, 0);
  $sizer->Add($self->$_, 1, Exp, 0) for($self->core_attribs);
  $self->SetAutoLayout(1);
  $self->SetSizer($sizer);
  $sizer->SetSizeHints($self);
  $self->SetMinSize(Wx::Size->new(0, -1)); # allow us to collapse
  $sizer->Show($_, 0) for(2..6);  # hide them all
  $self->Layout;
} # end subroutine __do_layout definition
########################################################################


=head2 __do_properties

  $self->__do_properties;

=cut

sub __do_properties {
  my $self = shift;

  $self->$_->SetBackgroundColour(Wx::Colour->new(244, 245, 255))
    for($self->core_attribs);
} # end subroutine __do_properties definition
########################################################################

=head2 init

  $sidebar->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;

  # init the sub objects
  foreach my $attrib ($self->core_attribs) {
    my $obj = $self->$attrib;
    $obj->init($frame) if($obj->can('init'));
  }

  # always pass focus to a useful child
  Wx::Event::EVT_SET_FOCUS($self, sub {$_[0]->focus_current($_[1])});
  $self->$set_current_item('libraries');

} # end subroutine init definition
########################################################################

=head2 core_attribs

  $self->core_attribs

=cut

sub core_attribs {
  return(qw(
    libraries
    contents
    search
    notes
    bookmarks
    highlights
  ));
} # end subroutine core_attribs definition
########################################################################


=head2 select_item

  $sb->select_item($name);

=cut

{
my %items = ( # just the index in the sizer
  libraries  => 1,
  contents   => 2,
  search     => 3,
  notes      => 4,
  bookmarks  => 5,
  highlights => 6,
);

sub select_item {
  my $self = shift;
  my ($name) = @_;

  $items{$name} or croak("'$name' is not valid");

  $self->sizer->Show($_, 0) for(1..6);  # hide them all
  $self->sizer->Show($items{$name}, 1); # show this
  $self->$_->Enable(1) for(map({'button_' . $_} keys(%items)));
  my $button = 'button_' . $name;
  $self->$button->Enable(0);
  $self->sizer->Layout;
  $self->$set_current_item($name); # by name only
  $self->$name->SetFocus;
} # end subroutine select_item definition
}
########################################################################


=head2 focus_current

Focus the current_item.

  $self->focus_current($event);

=for podcoverage_private SetFocus

=cut

# Wx tries to focus our first child (button), which is useless
use Method::Alias qw(SetFocus focus_current);
sub focus_current {
  my $self = shift;

  my $current = $self->current_item;
  $current or croak('nothing here to focus');
  $self->$current->SetFocus;
} # end subroutine focus_current definition
########################################################################

# XXX in flux
sub _ad_split {
  my $self = shift;
  my $aw = $self->adwidget;

  if($aw) {
    $self->sizer->Show($aw, ! $aw->IsShown);
  }
  else { # TODO: make this another method
    my $button = Wx::BitmapButton->new($self, -1,
      Wx::Bitmap->new(
        dtRdr->data_dir . 'gui_default/images/custom_space.png',
        BT"PNG"
      )
    );
    $button->SetSize($button->GetBestSize());
    $self->sizer->Add($button, 0, Ams, 0);
    $self->{adwidget} = $button;
  }
  $self->sizer->Layout;
} # end sub _ad_split



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
