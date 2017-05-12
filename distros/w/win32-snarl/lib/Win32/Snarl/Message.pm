package Win32::Snarl::Message;

use strict;
use warnings;

use Win32::Snarl;

sub show {
  my ($class, $title, $text, %options) = @_;
  
  my $id;
  
  if (exists $options{class}) {
    $id = Win32::Snarl::ShowMessageEx(
      $options{class},
      $title,
      $text,
      $options{timeout},
      $options{icon},
      $options{hwnd},
      $options{reply},
      $options{sound},
    );
  } else {
    $id = Win32::Snarl::ShowMessage(
      $title,
      $text,
      $options{timeout},
      $options{icon},
      $options{hwnd},
      $options{reply},
    );
  }
    
  bless [$id], $class;
}

sub visible {
  my ($self) = @_;
  
  Win32::Snarl::IsMessageVisible($self->[0]);
}

sub hide {
  my ($self) = @_;
  
  Win32::Snarl::HideMessage($self->[0]);
}

sub update {
  my ($self, $title, $text) = @_;
  
  Win32::Snarl::UpdateMessage($self->[0], $title, $text);
}

1;
