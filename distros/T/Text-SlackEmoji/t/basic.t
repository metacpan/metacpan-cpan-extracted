use strict;
use warnings;
use utf8;

use Test::File::ShareDir
  -share => { -dist => { 'Text-SlackEmoji' => 'share' } };

use Text::SlackEmoji;
use Test::More;

my $map = Text::SlackEmoji->emoji_map;

is($map->{atom_symbol}, "⚛", "the map loads as needed");
is($map->{smile}, "😄", "the map loads as needed");

done_testing;
