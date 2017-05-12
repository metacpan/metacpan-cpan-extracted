#!/usr/bin/perl -w

# Needed to get PERL5LIB under taint mode.
# See - http://objectmix.com/perl/78372-taint-breaking-perl5lib-over-zealous-cgi.html
use Config;
use lib map { /(.*)/ } $ENV{PERL5LIB} =~ /([^$Config{path_sep}]+)/g;

use strict;

use Test::More tests => 1;
sub is_tainted
{
    return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
}

# TEST
ok (is_tainted($ENV{'PATH'}), "The -T flag was passed.");
