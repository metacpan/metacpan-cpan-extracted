use Test::More tests => 5;

BEGIN {
    use_ok('Class::Accessor::Grouped');
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
	use_ok( 'WWW::BashOrg' );
}

diag( "Testing WWW::BashOrg $WWW::BashOrg::VERSION, Perl $], $^X" );
