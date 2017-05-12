use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Wx::Perl::RadioBoxDialog' ) || print "Bail out!\n";
}

diag( "Testing Wx::Perl::RadioBoxDialog $Wx::Perl::RadioBoxDialog::VERSION, Perl $], $^X" );
