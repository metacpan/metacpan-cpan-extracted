use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 26;
use Unicode::Util qw( grapheme_rindex );

# Simple - with just a single char

is grapheme_rindex('Hello World', 'H'),  0, 'One char, at beginning';
is grapheme_rindex('Hello World', 'l'),  9, 'One char, in the middle';
is grapheme_rindex('Hello World', 'd'), 10, 'One char, in the end';
is grapheme_rindex('Hello World', 'x'), -1, 'One char, no match';

is grapheme_rindex('Hello World', 'l', 10),  9, 'One char, first match, pos @ end';
is grapheme_rindex('Hello World', 'l',  9),  9, '- 1. match again, pos @ match';
is grapheme_rindex('Hello World', 'l',  8),  3, '- 2. match';
is grapheme_rindex('Hello World', 'l',  2),  2, '- 3. match';
is grapheme_rindex('Hello World', 'l',  1), -1, '- no more matches';

# Simple - with a string

is grapheme_rindex('Hello World', 'Hello'),       0, 'Substr, at beginning';
is grapheme_rindex('Hello World', 'o W'),         4, 'Substr, in the middle';
is grapheme_rindex('Hello World', 'World'),       6, 'Substr, at the end';
is grapheme_rindex('Hello World', 'low'),        -1, 'Substr, no match';
is grapheme_rindex('Hello World', 'Hello World'), 0, 'Substr eq Str';

# Empty strings

is grapheme_rindex('Hello World', ''),      11, 'Substr is empty';
is grapheme_rindex('',            ''),       0, 'Both strings are empty';
is grapheme_rindex('',            'Hello'), -1, 'Only main-string is empty';

is grapheme_rindex('Hello', '',   3), 3, 'Substr is empty, pos within str';
is grapheme_rindex('Hello', '',   5), 5, 'Substr is empty, pos at end of str';
is grapheme_rindex('Hello', '', 999), 5, 'Substr is empty, pos > length of str';

# More difficult strings

is grapheme_rindex('abcdabcab', 'abcd'), 0, 'Start-of-substr matches several times';
is grapheme_rindex('uuúuúuùù',  'úuù'),  4, 'Accented chars';
is grapheme_rindex('Ümlaut',    'Ü'),    0, 'Umlaut';
is grapheme_rindex('☚ perl ☛',  'e'),    3, 'grapheme_rindex with non-latin-1 strings';

is grapheme_rindex('what are these « » unicode characters for ?', 'uni'), 19, 'over unicode characters';

# grapheme_rindex on non-strings

is grapheme_rindex(3459, 5), 2, 'grapheme_rindex on integers';
