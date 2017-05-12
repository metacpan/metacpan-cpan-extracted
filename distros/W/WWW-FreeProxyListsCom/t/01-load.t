#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

diag( "Testing WWW::FreeProxyListsCom $WWW::FreeProxyListsCom::VERSION, Perl $], $^X" );

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('WWW::Mechanize');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('Devel::TakeHashArgs');
    use_ok('Class::Accessor::Grouped');
	use_ok( 'WWW::FreeProxyListsCom' );
}

done_testing();
