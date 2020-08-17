use strict;
use warnings;
use utf8;

use Test::File::ShareDir
  -share => { -dist => { 'Text-SlackEmoji' => 'share' } };

use Text::SlackEmoji;
use Test::More;

my $map = Text::SlackEmoji->emoji_map;

is($map->{smile}, "😄", "emojis are happiness");
is($map->{atom_symbol}, "⚛️", "codepoint with explicit variant selector");

done_testing;
