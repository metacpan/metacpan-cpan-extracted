package WWW::Jawbone::Up::Score::Move;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

__PACKAGE__->add_accessors(
  qw(distance active_time longest_active longest_idle));
__PACKAGE__->add_accessors({
  steps        => 'bg_steps',
  active_burn  => 'calories',
  resting_burn => 'bmr_calories',
});

sub total_burn {
  my $self = shift;
  return $self->active_burn + $self->resting_burn;
}

1;
