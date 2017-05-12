#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Test::HTTP::AnyEvent::Server));
}

diag(qq(Test::HTTP::AnyEvent::Server v$Test::HTTP::AnyEvent::Server::VERSION, Perl $], $^X));
