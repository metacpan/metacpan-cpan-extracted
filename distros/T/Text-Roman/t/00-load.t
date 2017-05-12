#!perl
use strict;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Text::Roman));
}

diag(qq(Text::Roman v$Text::Roman::VERSION, Perl $], $^X));
