package dtRdr::GUI::Wx::Frame0;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use strict;
use warnings;

use Wx ();

use WxPerl::ShortCuts;

use wxPerl::Constructors;

use base 'wxPerl::Frame';

=head1 NAME

dtRdr::GUI::Wx::Frame0 - layout for toplevel frame

=head1 SYNOPSIS

This module was originally part of the glade scheme.  There is no more
glade scheme.

=cut

=head2 new

  $frame = Frame->new(%opts);

=cut

sub new {
  my $class = shift;
  my (%opts) = @_;
  $opts{size} ||= Wx::Size->new(800,600);

  my $self = $class->SUPER::new(undef, '', %opts);

  $self->_create_children;

  $self->__set_properties();
  $self->__do_layout();

  #$self->setup_progressbar;

  return $self;
} # end subroutine new definition
########################################################################

# END OF REAL CODE
########################################################################

sub __set_properties {
  my $self = shift;

  $self->SetTitle("dotReader");
  $self->SetIcon(
    Wx::Icon->new(dtRdr->data_dir."gui_default/icons/dotreader.ico", BT"ICO"),
  );

} # end __set_properties
########################################################################

sub __do_layout {
  my $self = shift;

  $self->{sizer_1} = Wx::BoxSizer->new(wV);

  $self->right_window->SplitHorizontally($self->bv_manager, $self->note_viewer);

  $self->window_1->SplitVertically($self->sidebar, $self->right_window, 195);
  $self->{sizer_1}->Add($self->{window_1}, 1, Exp, 0);
  $self->SetAutoLayout(1);
  $self->SetSizer($self->{sizer_1});
  $self->Layout();
  $self->Centre();

} # end __do_layout

=head2 _create_children

Create child widgets.

  $self->_create_children;

=cut

sub _create_children {
  my $self = shift;

  $self->{window_1} = Wx::SplitterWindow->new($self, 501, DefPS, SP"3D|BORDER");
  $self->{right_window} = Wx::SplitterWindow->new($self->{window_1}, -1, DefPS, SP"3D|BORDER");

  use dtRdr::GUI::Wx::NoteViewer;
  $self->{note_viewer} =
    dtRdr::GUI::Wx::NoteViewer->new($self->right_window, -1, DefPS);

  { # statusbar
    my @f = (
      [-3 => ''],
      [-1 => ''],
      [-1 => ''],
    );
    my $sb = $self->{statusbar} = $self->CreateStatusBar(scalar(@f));
    $sb->SetStatusWidths(map({$_->[0]} @f));
    { my $i = 0; $sb->SetStatusText($_->[1], $i++) for(@f); }
  }

  use dtRdr::GUI::Wx::Sidebar;
  $self->{sidebar} = dtRdr::GUI::Wx::Sidebar->new($self->{window_1}, -1);

  use dtRdr::GUI::Wx::BVManager;
  $self->{bv_manager} = dtRdr::GUI::Wx::BVManager->new($self->{right_window}, -1, DefPS);

  return();
} # end subroutine _create_children definition
########################################################################

=head1 AUTHOR

not it

=head1 COPYRIGHT

Copyright (C) 2006 OSoft, All Rights Reserved.

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

1;

# vim:ts=2:sw=2:et:sts=2:sta
