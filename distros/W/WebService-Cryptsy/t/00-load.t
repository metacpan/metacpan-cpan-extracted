#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 11;

BEGIN {
    use_ok('Carp');
    use_ok('Moo');
    use_ok('URI');
    use_ok('JSON::MaybeXS');
    use_ok('LWP::UserAgent');
    use_ok('LWP::Protocol::https');
    use_ok('Digest::SHA');
    use_ok('HTTP::Request::Common');
    use_ok('constant');
    use_ok('overload');

    use_ok( 'WebService::Cryptsy' ) || print "Bail out!\n";
}

diag( "Testing WebService::Cryptsy $WebService::Cryptsy::VERSION, Perl $], $^X" );