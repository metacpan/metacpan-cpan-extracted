#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Text::SpeedyFx));
};

diag(qq(Text::SpeedyFx v$Text::SpeedyFx::VERSION, Perl $], $^X));
