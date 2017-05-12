use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Difference' ) || print "Bail out!\n";
}

diag( "Testing Text::Difference $Text::Difference::VERSION, Perl $], $^X" );
