package CattySession;

use strict;
use warnings;

use Catalyst qw/
    Session
    Session::State::Cookie
    Session::Store::Dummy
/;
use Cwd;

__PACKAGE__->config(
    name => 'CattySession',
    root => cwd . '/t/root',
);

__PACKAGE__->setup;

1;

