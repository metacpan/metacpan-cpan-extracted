#!/usr/bin/perl -w

# Needed to get PERL5LIB under taint mode.
# See - http://objectmix.com/perl/78372-taint-breaking-perl5lib-over-zealous-cgi.html
use Config;
use lib map { /(.*)/ } $ENV{PERL5LIB} =~ /([^$Config{path_sep}]+)/g;

use strict;
use Test::More tests => 1;

my $num_warnings = 0;
{
    local $SIG{__WARN__} = sub { $num_warnings++; };
    eval ("#" . substr($ENV{'PATH'}, 0, 0));
}

# TEST
is ($num_warnings, 1, "The -t flag was passed.");
