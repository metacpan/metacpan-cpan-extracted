use strict;
use warnings;
use utf8;
use Test::Kantan;

sub X::y { die }

my $spy = Test::Kantan::spy_on('X', 'y')->and_returns(3);
ok { X->y eq 3 };

done_testing;

