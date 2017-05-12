use warnings;
use strict;
use Test::More;
use Text::Fuzzy;

# This tests what happens when a Unicode string is matched against a
# non-Unicode string.

# Case 1: the string in "new" is not Unicode, but it is compared
# against a Unicode string.

my $cat = Text::Fuzzy->new ('cat');
use utf8;
is ($cat->distance ('γάτος'), 5);

# Case 2: the string in "new" is Unicode, but it is compared against a
# non-Unicode string.

my $jcat = Text::Fuzzy->new ('にゃんこちゃん');
no utf8;
is ($jcat->distance ('mogaroon'), 8);

# Check Unicode against Unicode.

use utf8;
is ($jcat->distance ('ねこちゃん'), 3);

# Check no Unicode against no Unicode.

no utf8;
is ($cat->distance ('cart'), 1);

done_testing ();
