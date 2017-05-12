package WWW::Jawbone::Up::Score;

use 5.010;
use strict;
use warnings;

use base 'WWW::Jawbone::Up::JSON';

__PACKAGE__->add_subclass(move  => 'WWW::Jawbone::Up::Score::Move');
__PACKAGE__->add_subclass(sleep => 'WWW::Jawbone::Up::Score::Sleep');

1;
