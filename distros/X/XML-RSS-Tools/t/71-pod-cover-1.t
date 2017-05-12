#   $Id: 71-pod-cover-1.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

my $test_warn;
BEGIN {
    eval ' use Pod::Coverage; ';
    if ( $@ ) {
        plan( skip_all => 'Pod::Coverage not installled.' );
    }
    else {
        eval ' require Test::NoWarnings; ';
        if ( $@ ) {
            plan( tests => 1 );
            undef $test_warn;
        }
        else {
            plan( tests => 2 );
            $test_warn = 1;
        }
    }
}

my $pc = Pod::Coverage->new(
    package => 'XML::RSS::Tools',
    trustme => [qr/^(rss|xsl)_/]
);
ok( $pc->coverage == 1 );
if ( $test_warn ) { Test::NoWarnings::had_no_warnings(); }
