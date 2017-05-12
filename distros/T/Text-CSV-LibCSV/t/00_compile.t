use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Text::CSV::LibCSV');
    can_ok('Text::CSV::LibCSV', qw/new xs_parse opts strerror CSV_STRICT CSV_REPALL_NL/);
}

