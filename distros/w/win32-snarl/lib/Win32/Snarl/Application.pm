package Win32::Snarl::Application;

use strict;
use warnings;

use Win32::Snarl;

sub register {
  my ($class, $hwnd, $name, $reply, $icon) = @_;
  
  if ($icon) {
    Win32::Snarl::RegisterConfig2($hwnd, $name, $reply, $icon);
  } else {
    Win32::Snarl::RegisterConfig($hwnd, $name, $reply);
  } 
  
  bless [$hwnd, $name], $class;
}

sub alert {
  my ($self, $name) = @_;
  
  Win32::Snarl::RegisterAlert($self->[1], $name);
}

sub revoke {
  my ($self) = @_;
  
  Win32::Snarl::RevokeConfig($self->[0]);
}

sub DESTROY {
  my ($self) = @_;
  
  $self->revoke;
}

1;
