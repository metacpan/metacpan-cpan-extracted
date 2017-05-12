package dtRdr::GUI::Wx::Dialog::Password;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

use base 'dtRdr::GUI::Wx::Dialog::Password0';

use Class::Accessor::Classy;
rw 'config';
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::GUI::Wx::Dialog::Password - password dialog

=head1 SYNOPSIS

Ask the user for a username and password.

=cut

=head2 get_credentials

A class method ...

  my ($u, $p) = dtRdr::GUI::Wx::Dialog::Password->get_credentials(
    $parent,
    config => $object,
    uri    => $uri,
    realm  => $realm,
  );

=cut

sub get_credentials {
  my $package = shift;
  (@_ % 2) or croak "odd number of options in argument list";
  my ($parent, %opts) = @_;

  my %own_opts;
  foreach my $key (qw(config)) {
    exists($opts{$key}) or next;
    $own_opts{$key} = delete($opts{$key});
  }

  my %args;
  foreach my $key (qw(realm uri)) {
    $args{$key} = delete($opts{$key}) || '';
  }

  $opts{title} ||= 'Authentication Required';

  my $self = $package->new($parent, %opts);
  my $message = "Password required for '$args{realm}'" .
    ($args{uri} ? "\n($args{uri})" : '');
  # naive word-wrap because ->Wrap doesn't work
  $message =~ s/(.{40,50}\b)/$1\n/g;
  $self->label_message->SetLabel($message);
  #$self->label_message->Wrap; # XXX not there
  #$self->GetSizer->Layout;
  #$self->SetSize(Wx::Size->new(400,300));
  # uh, why am I repeating myself here?
  $self->GetSizer->SetSizeHints($self);
  $self->Layout();

  foreach my $key (keys %own_opts) {
    $self->${\("set_$key")}($own_opts{$key});
  }

  $self->init;

  $self->ShowModal == Wx::wxID_OK() or return;

  my ($u, $p) =
    (map({$self->${\('value_'.$_)}->GetValue} qw(username password)));

  if(my $config = $self->config) {
    my $cu = $config->username;
    my $cp = $config->password;
    if(not defined($cu) or (defined($cu) and ($u ne $cu))) {
      $config->set_username($u);
    }
    if($self->checkbox_save->IsChecked and
      not (defined($cp) and ($cp eq $p))
    ) {
      warn "write pasword";
      $config->set_password($p);# unless(defined($cp) and ($cp eq $p));
    }
  }

  return($u, $p)
} # end subroutine get_credentials definition
########################################################################

=head1 Setup

This dialog should work with or without a config object.

=head2 init

  $pw->init();

=cut

sub init {
  my $self = shift;

  # setup the events
  Wx::Event::EVT_INIT_DIALOG($self, sub {shift->init_dialog(@_)});
  #Wx::Event::EVT_SET_FOCUS($self, sub {warn "focus!"});
  #Wx::Event::EVT_TEXT_ENTER($self, $self->$_, sub {warn "enter!"; $self->OnOK})
  #  for(qw(value_username value_password));

  Wx::Event::EVT_TEXT_ENTER($self, $self->value_username,
    sub {$self->value_password->SetFocus});
  Wx::Event::EVT_TEXT_ENTER($self, $self->value_password,
    sub {$self->OnOK});

  # XXX yet another difficult thing to get right
  Wx::Event::EVT_KEY_DOWN($self->checkbox_save, sub {
    my ($obj, $evt) = @_;
    my $code = $evt->GetKeyCode;
    if($code == Wx::WXK_RETURN()) {
      $self->OnOK
    }
    elsif($code == Wx::WXK_ESCAPE()) {
      $self->Close;
    }
    else {
      $evt->Skip;
    }
  });

  if(1) { # XXX grr! ShowModal ignores my SetFocus in init_dialog!
    my $once = 0;
    Wx::Event::EVT_SET_FOCUS($self->value_username,
      sub {
        $once++ and return;
        if($self->config and defined($self->config->username)) {
          $self->value_password->SetFocus
        }
      }
    );
    # and this as a workaround for the workaround!
    Wx::Event::EVT_SET_FOCUS($self->value_password, sub { $once++; });
  }

} # end subroutine init definition
########################################################################

=head2 init_dialog

  $self->init_dialog($evt);

=cut

sub init_dialog {
  my $self = shift;
  $self->TransferDataToWindow;

  my $empty = 'value_username';
  if(my $config = $self->config) {
    my @populate = map({[$_, 'value_' . $_]} qw(username password));
    foreach my $field (@populate) {
      my ($from, $to) = @$field;
      if(defined(my $val = $config->$from())) {
        $self->$to()->SetValue($val);
      }
    }
    $empty = 'value_password' if(defined($config->username));
  }
  # warn "empty is $empty";

  $self->$empty->SetFocus;

  $self->checkbox_save->Enable(0) unless($self->config);
} # end subroutine init_dialog definition
########################################################################


=head2 set_config

  $self->set_config($config);

=cut

sub set_config {
  my $self = shift;
  my ($config) = @_;
  
  $self->checkbox_save->Enable(defined($config) ? 1 : 0);

  $self->SUPER::set_config($config);
} # end subroutine set_config definition
########################################################################

#sub Show {warn "show?"; shift->SUPER::Show(@_)};
#sub ShowModal {warn "huh?"; shift->SUPER::ShowModal};
#sub SetFocus {warn "SetFocus"; shift->SUPER::SetFocus(@_)};
#sub OnSetFocus {warn "OnSetFocus"; shift->SUPER::OnSetFocus(@_)};

=head2 OnOK

What?  This didn't get bound?

  $self->OnOK;

=cut

sub OnOK {
  my $self = shift;
  if($self->IsModal) {
    $self->EndModal(Wx::wxID_OK());
  }
  else {
    $self->SetReturnCode(Wx::wxID_OK());
    $self->Show(0);
  }
} # end subroutine OnOK definition
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
