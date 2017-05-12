use strict;
use warnings;

BEGIN {
    $ENV{'PERL_URI_XSESCAPE'} = 0;
}

use URI::Escape;
use URI::XSEscape;
use Test::More tests => 1;

## no critic
my $xsescape_glob
    = do { no strict 'refs'; *{'URI::XSEscape::uri_escape'}{'CODE'} };
my $escape_glob
    = do { no strict 'refs'; *{'URI::Escape::uri_escape'}{'CODE'} };

isnt( "$escape_glob", "$xsescape_glob",
    'Do not override stuff when PERL_URI_XSESCAPE=0' );
