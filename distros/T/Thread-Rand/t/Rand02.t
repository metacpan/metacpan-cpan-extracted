BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 10;
use strict;
use warnings;

BEGIN {use_ok( 'Thread::Rand' )}

Thread::Rand->global;

my $require = 'randtest';
$require = "t/$require" unless $ENV{PERL_CORE};
require $require;
