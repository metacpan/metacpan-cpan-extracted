#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;

my $class = 'Text::Guess::Script';

use_ok($class);

my $object = new_ok($class);

if (1) {
  ok($object->new());
  ok($object->new(1,2));
  ok($object->new({}));
  ok($object->new({a => 1}));

  ok($class->new());
}


is(Text::Guess::Script->guess(''),            '',      'empty is empty');
is(Text::Guess::Script->guess(' '),           'Zyyy',  'space is Zyyy (Common)');
is(Text::Guess::Script->guess("\x{E006}"),    'Zzzz', 'PUA is Zzzz (Unknown)');
is(Text::Guess::Script->guess('Hello World'), 'Latn', 'is Latn (Latin)');
is(Text::Guess::Script->guess('一'),          'Hani', 'is Hani (Han)');
is(Text::Guess::Script->guess('し'),          'Hira', 'is Hira (Hiragana)');
is(Text::Guess::Script->guess('ン'),          'Kana', 'is Kana (Katakana)');

# 0x0964 Block: [ Bengali, Devanagari, Gurumukhi, Oriya ]
# U+0964 DEVANAGARI DANDA (Other_Punctuation)
is(Text::Guess::Script->guess("\x{0964}"), 'Zyyy', 'U+0964 is Zyyy (Common)');


is(Text::Guess::Script->guesses(' ')->[0][2],           'Common',   'space is Zyyy (Common)');
is(Text::Guess::Script->guesses("\x{E006}")->[0][2],    'Unknown',  'PUA is Zzzz (Unknown)');
is(Text::Guess::Script->guesses('Hello World')->[0][2], 'Latin',    'is Latn (Latin)');
is(Text::Guess::Script->guesses('一')->[0][2],          'Han',      'is Hani (Han)');
is(Text::Guess::Script->guesses('し')->[0][2],          'Hiragana', 'is Hira (Hiragana)');
is(Text::Guess::Script->guesses('ン')->[0][2],          'Katakana', 'is Kana (Katakana)');

# 0x0964 Block: [ Bengali, Devanagari, Gurumukhi, Oriya ]
# U+0964 DEVANAGARI DANDA (Other_Punctuation)
is(Text::Guess::Script->guesses("\x{0964}")->[0][2],    'Common',   'U+0964 is Zyyy (Common)');


is(scalar @{Text::Guess::Script->guesses('')},            0,      'empty is empty list');
is(scalar @{Text::Guess::Script->guesses('Hello World')}, 2,      'text has list of 2 elements');
is(Text::Guess::Script->guesses('Hello World')->[0]->[0], 'Latn', 'text 1st is Latn (Latin)');
is(Text::Guess::Script->guesses('Hello World')->[1]->[0], 'Zyyy', 'text 2nd is Zyyy (Common)');

done_testing;
