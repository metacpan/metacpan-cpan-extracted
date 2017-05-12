#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Text::Fingerprint));
};

diag(qq(Text::Fingerprint v$Text::Fingerprint::VERSION, Perl $], $^X));
