package WWW::Jawbone::Up::JSON;

use 5.010;
use strict;
use warnings;

use Carp;
use DateTime;

sub patch {
  my ($class, $method, $code) = @_;

  no strict 'refs';
  *{ $class . '::' . $method } = $code;
}

sub add_accessors {
  my $class = shift;

  foreach my $arg (@_) {
    if (ref $arg eq '') {
      $class->patch($arg, sub { my $self = shift; return $self->{$arg} });
    } elsif (ref $arg eq 'HASH') {
      foreach my $name (keys %$arg) {
        my $value = $arg->{$name};
        $class->patch($name, sub { my $self = shift; return $self->{$value} });
      }
    } else {
      croak "Invalid argument type: " . ref $arg;
    }
  }
}

sub add_subclass {
  my ($class, $method, $subclass) = @_;

  $class->patch(
    $method => sub {
      my $self = shift;

      if (ref $self->{$method} ne $subclass) {
        eval "use $subclass";
        croak $@ if $@;
        $self->{$method} = $subclass->new($self->{$method});
      }

      return $self->{$method};
    });
}

sub add_time_accessors {
  my $class = shift;

  foreach my $method (@_) {
    $class->patch(
      $method => sub {
        my $self = shift;
        return DateTime->from_epoch(
          epoch     => $self->{ 'time_' . $method },
          time_zone => $self->timezone,
        );
      });
  }
}

sub new {
  my ($class, $json) = @_;

  return bless $json, $class;
}

1;
