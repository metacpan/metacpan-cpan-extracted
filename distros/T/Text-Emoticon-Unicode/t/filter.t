use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use Text::Emoticon;

my $emo = Text::Emoticon->new('Unicode');

is $emo->filter(':) :-('), '☺ ☹', 'smiley w/o nose and frowney w/nose';
is $emo->filter(':( :-)'), '☹ ☺', 'frowney w/o nose and smiley w/nose';
