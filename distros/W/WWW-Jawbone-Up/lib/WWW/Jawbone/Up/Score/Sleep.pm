package WWW::Jawbone::Up::Score::Sleep;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

__PACKAGE__->add_accessors(qw(awakenings light awake time_to_sleep));

sub bedtime {
  my $self = shift;
  return $self->{goals}{bedtime}[0];
}

sub deep {
  my $self = shift;
  return $self->{goals}{deep}[0];
}

sub asleep {
  my $self = shift;
  return $self->light + $self->deep;
}

sub in_bed {
  my $self = shift;
  return $self->asleep + $self->awake;
}

1;
