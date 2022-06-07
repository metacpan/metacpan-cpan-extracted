
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 2;
use strict;
use warnings;

ok(!eval('use UNIVERSAL::dump qw/notexists/; 1'));
like($@, qr/Don't know how to install method "UNIVERSAL::notexists/);
done_testing;
