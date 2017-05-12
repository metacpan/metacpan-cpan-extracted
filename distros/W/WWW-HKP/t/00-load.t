#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('WWW::HKP');
}

diag("Testing WWW::HKP $WWW::HKP::VERSION, Perl $], $^X");

ok( WWW::HKP->new, 'instanciate' );
