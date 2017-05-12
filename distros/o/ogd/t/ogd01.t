BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 2;
use strict;
use warnings;

use_ok( 'ogd' ); # just for the record
can_ok( 'ogd',qw(
 register
) );
