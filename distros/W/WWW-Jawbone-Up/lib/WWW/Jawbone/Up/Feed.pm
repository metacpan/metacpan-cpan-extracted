package WWW::Jawbone::Up::Feed;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

use DateTime;

__PACKAGE__->add_accessors(
  qw(title date type reached_goal), {
    timezone => 'tz',
  });

__PACKAGE__->add_time_accessors(qw(created updated));

__PACKAGE__->add_subclass(user => 'WWW::Jawbone::Up::User');

sub image {
  my $self = shift;
  return 'https://jawbone.com' . $self->{image};
}

1;
