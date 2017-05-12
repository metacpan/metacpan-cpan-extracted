use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok 'Text::Levenshtein::Damerau', qw/edistance/ }
BEGIN { use_ok 'Text::Levenshtein::Damerau::PP', qw/pp_edistance/ }
