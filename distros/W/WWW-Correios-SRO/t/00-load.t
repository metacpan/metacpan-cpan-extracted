#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Correios::SRO' ) || print "Bail out!
";
}

diag( "Testing WWW::Correios::SRO $WWW::Correios::SRO::VERSION, Perl $], $^X" );
