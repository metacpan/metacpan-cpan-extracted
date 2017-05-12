BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 11;
use strict;
use warnings;

BEGIN {use_ok( 'Thread::Rand',qw(rand srand) )}

can_ok( 'Thread::Rand',qw(
 global
 import
 rand
 srand
) );

my $require = 'randtest';
$require = "t/$require" unless $ENV{PERL_CORE};
require $require;
