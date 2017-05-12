#!perl -w
use strict;
use Test::More tests => 3;

BEGIN {
  use_ok('WebService::SongLyrics');
}

my $wsl = WebService::SongLyrics->new;

ok(ref $wsl eq "WebService::SongLyrics", "Object isa WebService::SongLyrics");
can_ok('WebService::SongLyrics', 'get_lyrics');
