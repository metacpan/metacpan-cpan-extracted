package WWW::Jawbone::Up::Workout;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

__PACKAGE__->add_accessors(qw(title), { complete => 'is_complete' });

__PACKAGE__->add_time_accessors(qw(created updated completed));

sub time {
  my $self = shift;
  return $self->{details}{time};
}

sub distance {
  my $self = shift;
  return $self->{details}{km};
}

sub steps {
  my $self = shift;
  return $self->{details}{steps};
}

sub intensity {
  my $self = shift;
  return $self->{details}{intensity} || 'easy';
}

sub total_burn {
  my $self = shift;
  return $self->{details}{calories};
}

sub timezone {
  my $self = shift;
  return $self->{details}{tz};
}

1;
