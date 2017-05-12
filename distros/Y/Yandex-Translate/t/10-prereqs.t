use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    for (qw{HTML::Entities HTTP::Tiny JSON URI::Escape utf8}) {
       require_ok($_) or BAIL_OUT("Couldn't load $_");
    }
}

