use utf8;
use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use Text::Sass::XS qw(:const);

is SASS_STYLE_NESTED,     0;
is SASS_STYLE_EXPANDED,   1;
#is SASS_STYLE_COMPACT,    2;
is SASS_STYLE_COMPRESSED, 3;

is SASS_SOURCE_COMMENTS_NONE,    0;
is SASS_SOURCE_COMMENTS_DEFAULT, 1;
is SASS_SOURCE_COMMENTS_MAP,     2;

done_testing;
