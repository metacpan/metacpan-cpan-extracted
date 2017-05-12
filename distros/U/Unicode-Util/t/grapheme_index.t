use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 26;
use Unicode::Util qw( grapheme_index );

# Simple - with just a single char

is grapheme_index('Hello World', 'H'),  0, 'One char, at beginning';
is grapheme_index('Hello World', 'l'),  2, 'One char, in the middle';
is grapheme_index('Hello World', 'd'), 10, 'One char, in the end';
is grapheme_index('Hello World', 'x'), -1, 'One char, no match';

is grapheme_index('Hello World', 'l',  0),  2, 'One char, find first match, pos = 0';
is grapheme_index('Hello World', 'l',  2),  2, '- 1. match again, pos @ match';
is grapheme_index('Hello World', 'l',  3),  3, '- 2. match';
is grapheme_index('Hello World', 'l',  4),  9, '- 3. match';
is grapheme_index('Hello World', 'l', 10), -1, '- no more matches';

# Simple - with a string

is grapheme_index('Hello World', 'Hello'),       0, 'Substr, at beginning';
is grapheme_index('Hello World', 'o W'),         4, 'Substr, in the middle';
is grapheme_index('Hello World', 'World'),       6, 'Substr, at the end';
is grapheme_index('Hello World', 'low'),        -1, 'Substr, no match';
is grapheme_index('Hello World', 'Hello World'), 0, 'Substr eq Str';

# Empty strings

is grapheme_index('Hello World', ''),       0, 'Substr is empty';
is grapheme_index('',            ''),       0, 'Both strings are empty';
is grapheme_index('',            'Hello'), -1, 'Only main-string is empty';

is grapheme_index('Hello', '',   3),  3, 'Substr is empty, pos within str';
is grapheme_index('Hello', '',   5),  5, 'Substr is empty, pos at end of str';
is grapheme_index('Hello', '', 999),  5, 'Substr is empty, pos > length of str';

# More difficult strings

is grapheme_index('ababcabcd', 'abcd'), 5, 'Start-of-substr matches several times';
is grapheme_index('uuúuúuùù',  'úuù'),  4, 'Accented chars';
is grapheme_index('Ümlaut',    'Ü'),    0, 'Umlaut';

is grapheme_index(1234, 3),   2, 'index on non-strings';
is grapheme_index(1023, '0'), 1, 'grapheme_index($str, "0") works';
is grapheme_index(1023, 0),   1, 'grapheme_index($str, 0) works';
