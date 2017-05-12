use strict;
use warnings;
use Test::More;
use Unicode::Security qw(mixed_script_confusable);

is mixed_script_confusable("p\x{0430}yp\x{0430}l"), 1, 'paypal';
is mixed_script_confusable("1i\x{03BD}\x{0435}"), 1, '1ive';
is mixed_script_confusable("z\x{044F}a"), '', 'zra';

# is mixed_script_confusable("toys-\x{044F}-us"), '', 'toys-r-us';
# This test case is mentioned here:
#   http://www.unicode.org/reports/tr39/#Mixed_Script_Confusables
# where it specifically states:
#   'there is no Cyrillic character that looks like "t" or "u"'
# But confusablesWholeScript.txt does list the range:
#   0068..0079    ; Latn; Cyrl; A # [18] (h..y)  LATIN SMALL LETTER H..LATIN SMALL LETTER Y

done_testing;
