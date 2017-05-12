use strict;
use warnings;
use utf8;
use Test::More;
use Time::Piece::Plus ();
use Time::Piece ();

is(Time::Piece::Plus->localtime->epoch, Time::Piece::Plus->gmtime->epoch);
is(Time::Piece->localtime->epoch, Time::Piece::Plus->localtime->epoch);

done_testing;
