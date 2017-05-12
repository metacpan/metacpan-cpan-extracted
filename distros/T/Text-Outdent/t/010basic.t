use Test::More tests => 2;
use strict;
require_ok('Text::Outdent');
use_ok('Text::Outdent', qw/
    outdent
    outdent_all
    outdent_quote
    expand_leading_tabs
/);
