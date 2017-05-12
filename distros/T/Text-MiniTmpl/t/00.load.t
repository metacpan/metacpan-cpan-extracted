use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Text::MiniTmpl' ) or BAIL_OUT('unable to load module') }

diag( "Testing Text::MiniTmpl $Text::MiniTmpl::VERSION, Perl $], $^X" );
