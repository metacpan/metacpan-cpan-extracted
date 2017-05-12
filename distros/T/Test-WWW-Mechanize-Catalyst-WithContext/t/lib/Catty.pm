package Catty;

use strict;
use warnings;

use Catalyst qw/
    Session
    Session::State::Cookie
    Session::Store::Dummy
/;

use Cwd;

__PACKAGE__->config(
    name => 'Catty',
    root => cwd . '/t/root',
);
__PACKAGE__->setup();
__PACKAGE__->log->levels("fatal");

1;
