use Test::More tests => 3;


BEGIN{
	$ENV{PERL_MACRO_DEBUG} = 0;
	use_ok( 'macro' );

	use_ok( 'macro::filter' );
	use_ok( 'macro::compiler' );
}
diag( "Testing macro $macro::VERSION" );

