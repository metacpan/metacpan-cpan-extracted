package Mine::Once;

use parent 'Zing::Single';

our $DATA = 0;

sub perform {
  $DATA++
}

1;
