#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'WWW::TamperData' );
    my $obj = WWW::TamperData->new;
    isa_ok( $obj, 'WWW::TamperData' );
}

diag( "Testing WWW::TamperData $WWW::TamperData::VERSION, Perl $], $^X" );

