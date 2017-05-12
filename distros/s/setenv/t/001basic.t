BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

use Test::More tests => 7;

use_ok( 'setenv' ); # just for the record

my $keys;
BEGIN { $keys = keys %ENV };

no setenv;

BEGIN { is( scalar keys %ENV, 0, 'no environment left' ) };

BEGIN { ok( !$ENV{FOOBAR}, 'not set at first' ) };

use setenv FOOBAR => 'foobar';

BEGIN { is( $ENV{FOOBAR}, 'foobar', 'check if set later at compile time' ) };

no setenv qw( FOOBAR );

BEGIN { ok( !$ENV{FOOBAR}, 'not set after being removed' ) };

use setenv FOOBAR => 'foobar2';

BEGIN { is( $ENV{FOOBAR}, 'foobar2', 'check if set again at compile time' ) };

is( $ENV{FOOBAR}, 'foobar2', 'check if set later at run time' );
