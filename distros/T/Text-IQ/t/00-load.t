#!perl 

use Test::More;

eval "use Text::Aspell";
plan skip_all => "Text::Aspell unavailable" if $@;
use_ok( 'Text::IQ' );

diag( "Testing Text::IQ $Text::IQ::VERSION, Perl $], $^X" );

done_testing();
