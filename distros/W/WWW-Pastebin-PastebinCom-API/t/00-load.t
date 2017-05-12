#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 6;

BEGIN {
    use_ok('Carp');
    use_ok('LWP::UserAgent');
    use_ok('HTTP::Cookies');
    use_ok('Class::Data::Accessor');
    use_ok('overload');
    use_ok( 'WWW::Pastebin::PastebinCom::API' ) || print "Bail out!\n";
}

diag( "Testing WWW::Pastebin::PastebinCom::API $WWW::Pastebin::PastebinCom::API::VERSION, Perl $], $^X" );
