use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok('Text::Migemo', ':all');
}

can_ok('Text::Migemo', 'new');
can_ok('Text::Migemo', 'open');
can_ok('Text::Migemo', 'load');
can_ok('Text::Migemo', 'query');
can_ok('Text::Migemo', 'is_enable');
can_ok('Text::Migemo', 'set_operator');
can_ok('Text::Migemo', 'get_operator');
