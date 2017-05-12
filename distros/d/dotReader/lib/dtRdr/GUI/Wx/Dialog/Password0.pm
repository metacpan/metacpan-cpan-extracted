package dtRdr::GUI::Wx::Dialog::Password0;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

use wxPerl::Styles qw(style wxVal ID);

use wxPerl::Constructors;
use base 'wxPerl::Dialog';

use Class::Accessor::Classy;
ro qw(
  label_message
  label_username
  label_password
  value_username
  value_password
  checkbox_save
  button_cancel
  button_ok
);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::Dialog::Password0 - re TextEntryDialog

=head1 SYNOPSIS

Just the layout.

=cut

=head2 new

  $thing = Class->new($parent, %opts);

=cut

sub new {
  my $class = shift;
  my $parent = shift;
  my $title;
  if(@_ % 2) {
    $title = shift;
  }
  my (%opts) = @_;
  $title = delete($opts{title}) || 'Enter Password';

  $opts{size} ||= Wx::Size->new(280, 100);

  my $self = $class->SUPER::new($parent, $title, %opts);

  $self->_create_children;
  $self->__set_properties;
  $self->__do_layout;

  return($self);
} # end subroutine new definition
########################################################################

=head2 _create_children

  $self->_create_children;

=cut

sub _create_children {
  my $self = shift;

  foreach my $item (
  [label_message  => StaticText => 'we need a password'],
  [label_username => StaticText => "Username"],
  [label_password => StaticText => "Password"],
  [value_username => TextCtrl   => '', style(te => 'process_enter')],
  [value_password => TextCtrl   => '',
    style(te => 'process_enter|password')],
  [checkbox_save  => CheckBox   => 'Save password in config'],
	[button_cancel  => Button     => 'Cancel', ID('cancel')],
	[button_ok      => Button     => '&Ok', ID('ok')],
  ) {
    my @list = @$item;
    my $att = shift(@list);
    my $class = 'wxPerl::' . shift(@list);
    $self->{$att} = $class->new($self, @list);
  }

} # end subroutine _create_children definition
########################################################################

=head2 __set_properties

  $self->__set_properties;

=cut

sub __set_properties {
  my $self = shift;

  $self->value_username->SetMinSize(Wx::Size->new(200, -1));
} # end subroutine __set_properties definition
########################################################################

=head2 __do_layout

  $self->__do_layout;

=cut

sub __do_layout {
  my $self = shift;

  my $sL = Wx::BoxSizer->new(wxVal('vertical'));
  my $sR = Wx::BoxSizer->new(wxVal('vertical'));
  my $s2 = Wx::BoxSizer->new(wxVal('horizontal'));
  my $s3 = Wx::BoxSizer->new(wxVal('horizontal'));
  my $s0 = Wx::BoxSizer->new(wxVal('vertical'));

  $sL->Add($self->label_username, 1, wxVal('default'), 0);
  $sR->Add($self->value_username, 1, wxVal('expand'), 0);
  $sL->Add($self->label_password, 1, wxVal('default'), 0);
  $sR->Add($self->value_password, 1, wxVal('expand'), 0);
  $sL->Add(10, -1, 1, wxVal('adjust_minsize'), 0);
  $sR->Add($self->checkbox_save, 1, wxVal('expand'), 0);

  $s2->Add($sL, 0, wxVal('expand'), 0);
  $s2->Add($sR, 1, wxVal('expand'), 0);

  $s3->AddStretchSpacer(1);
  $s3->Add($self->button_cancel,  0, wxVal('expand'), 0);
  $s3->Add($self->button_ok,      0, wxVal('expand'), 0);

  $s0->Add($self->label_message, 0, wxVal('expand|all'), 15);
  $s0->Add($s2, 0, wxVal('expand|left|right'), 10);
  $s0->Add($s3, 0, wxVal('expand|left|right'), 0);

  $self->SetAutoLayout(1);
  $self->SetSizer($s0);
  $s0->SetSizeHints($self);
  $self->Layout();
  $self->Centre();

} # end subroutine __do_layout definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
