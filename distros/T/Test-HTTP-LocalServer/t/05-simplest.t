#!perl -w
use strict;
use warnings;
use Test::HTTP::LocalServer;

use Test::More tests => 1;

my $server = Test::HTTP::LocalServer->spawn;

ok "We'll finish in DESTROY";

# and ideally, $? is 0 still
