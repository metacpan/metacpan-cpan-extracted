use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Test::Pod::Snippets;

SKIP: {

    skip 'snippets_ok() is not there yet' => 1;

snippets_ok( 'blib/lib/Test/Pod/Snippets.pm' );

}

#my $xps= Test::Pod::Snippets->new;

#my $code = $xps->extract_snippets( 'blib/lib/Test/Pod/Snippets.pm' );
#warn $code;
#eval $code;

