package dtRdr::GUI::Wx::NoteEditor;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Wx;
use base 'dtRdr::GUI::Wx::NoteEditor0';

use dtRdr::Logger;

use Wx ();
use Wx::Event qw(
  EVT_BUTTON
  EVT_MENU
  EVT_CLOSE
  EVT_TEXT
  EVT_TEXT_ENTER
  EVT_KILL_FOCUS
);
use dtRdr::GUI::Wx::Utils qw(_accel);

use Class::Accessor::Classy;
ro qw(
  button_cancel
  button_submit
  text_ctrl_title
  text_ctrl_body
  checkbox_public
);
rw qw(
  saver
  reverter
);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::NoteEditorBase - base class for the NoteEditor

=head1 SYNOPSIS

=cut


=head2 init

  $editor->init;

=cut

sub init {
  my $self = shift;

  my @bmap = (
    [qw(cancel Close)],
    [qw(submit submit_edit)],
  );
  foreach my $row (@bmap) {
    my ($att, $method) = @$row;
    $att = 'button_' . $att;
    EVT_BUTTON($self, $self->$att->GetId, sub {$self->$method()});
  }

  EVT_CLOSE($self, sub {$self->cancel_edit; $_[1]->Skip});

  # make a table
  my $acc_table = Wx::AcceleratorTable->new(
    map({$self->_accel(@$_)}
      ['TAB',         sub { $self->text_ctrl_body->SetFocus; }],
      ['SHIFT+TAB',   sub { $self->text_ctrl_title->SetFocus; }],
      ['CTRL+RETURN', sub {$self->submit_edit; $_[1]->Skip}],
      ['ESCAPE',      sub {$self->Close}],
    ),
  );

  # set the title when the title field loses focus
  EVT_KILL_FOCUS($self->text_ctrl_title, sub {
    $self->_update_title;
    $_[1]->Skip;
  });
  # ENTER in the title goes to the body
  EVT_TEXT_ENTER($self, $self->text_ctrl_title, sub {
    $self->text_ctrl_body->SetFocus;
    $_[1]->Skip;
  });

  # TODO EVT_CHECKBOX enables server-choice drop-down

  # and set it active
  $_->SetAcceleratorTable($acc_table) for(
    $self,
    $self->text_ctrl_title,
    $self->text_ctrl_body,
    );
  $self->text_ctrl_title->SetFocus;
} # end subroutine init definition
########################################################################

=head2 set_fields

  $editor->set_fields(title => 'foo', body => 'bar');

=cut

sub set_fields {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;

  foreach my $key (keys(%args)) {
    my $attrib = 'text_ctrl_' . $key;
    $self->can($attrib) or croak("invalid argument '$key'");
    my $val = defined($args{$key}) ? $args{$key} : '';
    $self->$attrib->SetValue($val);
  }
  $self->_update_title;

} # end subroutine set_fields definition
########################################################################


=head2 _update_title

  $self->_update_title;

=cut

sub _update_title {
  my $self = shift;
  my $title = $self->text_ctrl_title->GetValue;
  if(length($title) > 20) {
    $title = substr($title, 0, 17);
    $title .=  '...';
  }
  # TODO maybe:  $title =~ s/[^\w \.]//g;
  $self->SetTitle((length($title) ? $title . ' - ' : '') . 'Note Editor');
} # end subroutine _update_title definition
########################################################################

=head2 set_saver

Set a subref (which takes no arguments) as the handler for the Save
action.  This will be called at autosave increments.

  $editor->set_saver(sub {...});

=cut

sub set_saver {
  my $self = shift;
  @_ or return($self->SUPER::set_saver(undef));
  my ($subref) = @_;
  ((ref($subref) || '') eq 'CODE') or croak("not a code reference");
  $self->SUPER::set_saver($subref);
} # end subroutine set_saver definition
########################################################################

=head2 set_reverter

Set a subref (which takes no arguments) as the handler for the deleting
action.  This will be called if the user opts to cancel during creation
of a new record.

  $editor->set_reverter(sub {...});

=cut

sub set_reverter {
  my $self = shift;
  @_ or return($self->SUPER::set_reverter(undef));
  my ($subref) = @_;
  ((ref($subref) || '') eq 'CODE') or croak("not a code reference");
  $self->SUPER::set_reverter($subref);
} # end subroutine set_reverter definition
########################################################################

=head2 cancel_edit

  $editor->cancel_edit;

=cut

sub cancel_edit {
  my $self = shift;
  if(my $reverter = $self->reverter) {
    WARN("revert");
    $reverter->();
  }
  WARN("cancel");
} # end subroutine cancel_edit definition
########################################################################

=head2 submit_edit

  $editor->submit_edit;

=cut

sub submit_edit {
  my $self = shift;
  WARN("submit");
  if(my $saver = $self->saver) {
    $saver->();
  }
  else {
    die "cannot save";
  }
  $self->set_reverter();
  $self->Close;
} # end subroutine submit_edit definition
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
