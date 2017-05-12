
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 2;
use strict;
use warnings;

use_ok( 'ifdef','_testing_' );
can_ok( 'ifdef',qw(
 import
 oneline
 process
 reset
) );
