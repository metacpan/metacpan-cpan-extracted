package dtRdr::GUI::Wx::Dialog::License;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


=head1 NAME

dtRdr::GUI::Wx::Dialog::License - the license dialog box

=head1 SYNOPSIS

=cut

use Wx qw(
  wxDefaultSize
  wxDefaultPosition
  wxDEFAULT_DIALOG_STYLE
  wxVERTICAL
  wxHORIZONTAL
  wxTE_MULTILINE
  wxTE_READONLY
  wxTE_DONTWRAP
  wxADJUST_MINSIZE
  wxEXPAND
  WXK_ESCAPE
);
use Wx::Event ();

use dtRdr;
use dtRdr::GUI::Wx::Utils qw(_accel);

use base qw(Wx::Dialog);

use Class::Accessor::Classy;
ro qw(
  sizer
  bsizer
  label
  text_ctrl
  dismiss_button
  details_button
);
no  Class::Accessor::Classy;

=head2 new

  my $search = dtRdr::GUI::Wx::Dialog::License->new($parent, blah blah);

=cut

sub new {
  my $class = shift;
	my ($parent, @args) = @_;
  my ($id, $title, $pos, $size, $style, $name) = @args;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = "dotReader License" unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = Wx::Size->new(550,380) unless defined $size;
	$style = wxDEFAULT_DIALOG_STYLE unless defined $style;
	$name   = ""                 unless defined $name;
  @args = ($id, $title, $pos, $size, $style, $name);

  my $self = $class->SUPER::new($parent, @args);

  $self->__create_children;
  $self->__do_layout;

  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 __create_children

  $self->__create_children;

=cut

sub __create_children {
  my $self = shift;

  my $labeltext = 'OSoft dotReader(TM) License';
  my @PS = (wxDefaultPosition, wxDefaultSize);
	#$self->{label} = Wx::StaticText->new($self, -1, $labeltext, @PS);
	$self->{text_ctrl} = Wx::TextCtrl->new($self, -1, "", @PS,
    wxTE_MULTILINE|wxTE_READONLY|wxTE_DONTWRAP);
	$self->{dismiss_button} = Wx::Button->new($self, -1, "&Close");
	$self->{details_button} = Wx::Button->new($self, -1, "&Details");
} # end subroutine __create_children definition
########################################################################

=head2 __do_layout

  $self->__do_layout;

=cut

sub __do_layout {
  my $self = shift;

	my $sizer = $self->{sizer} = Wx::BoxSizer->new(wxVERTICAL);
	my $bsizer = $self->{bsizer} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->label and $sizer->Add($self->label, 0, wxADJUST_MINSIZE, 0);
	$sizer->Add($self->text_ctrl, 1, wxEXPAND, 0);
	$bsizer->Add(20, 20, 1, wxEXPAND, 0);
	$bsizer->Add($self->details_button, 0, wxADJUST_MINSIZE, 0);
	$bsizer->Add($self->dismiss_button, 0, wxADJUST_MINSIZE, 0);
	$sizer->Add($bsizer, 0, wxEXPAND, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($sizer);
	#$sizer->Fit($self);
	#$sizer->SetSizeHints($self);
	$self->Layout();
} # end subroutine __do_layout definition
########################################################################

=head2 init

  $self->init($frame);

=cut

sub init {
  my $self = shift;
  my ($frame) = @_;

  {
    my @profiles = (
      {text => dtRdr->get_LICENSE, label => '&Details'},
      {text => dtRdr->get_COPYING, label => 'No &Details'},
    );
    my $switch = sub {
      push(@profiles, (my $current = shift(@profiles)));
      $self->text_ctrl->SetValue($current->{text});
      $self->details_button->SetLabel($current->{label});
    };
    $switch->(); # init
    Wx::Event::EVT_BUTTON($self, $self->details_button, $switch);
  }

  Wx::Event::EVT_BUTTON($self, $self->dismiss_button, sub {$self->Close});
  $self->SetAcceleratorTable(Wx::AcceleratorTable->new(
    map({$self->_accel(@$_)}
      ['ESCAPE',      sub {$self->Close}],
    ),
  ));
  $self->dismiss_button->SetFocus;
  return($self); # allow chaining
} # end subroutine init definition
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
