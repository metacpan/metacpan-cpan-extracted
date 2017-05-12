package WWW::Jawbone::Up::Tick;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

__PACKAGE__->add_accessors(
  qw(distance active_time aerobic calories steps time speed));

1;
