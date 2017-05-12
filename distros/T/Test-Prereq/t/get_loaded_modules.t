use Test::More 0.95;

use_ok( 'Test::Prereq' );

subtest 'modules' => sub {
	my $modules = Test::Prereq->_get_loaded_modules();
	my @keys = sort keys %$modules;

	my @expected = sort qw(
		Carp
		Cwd
		ExtUtils::MakeMaker
		File::Find
		Module::Build
		Module::Extract::Use
		Test::Builder::Module
		Test::More
		Test::Prereq
		Test::Prereq::Build
		feature
		lib
		parent
		strict
		utf8
		vars
		warnings
		);

	is_deeply( \@keys, \@expected, 'Right modules for modules and tests' )
		or
	diag( "Didn't find right modules!\n\tFound < @keys >\n\tExpected < @expected >\n" );
	};

done_testing();

__END__

TODO: {
local $TODO = "This interface changed, so these tests are not valid";

my $modules = Test::Prereq->_get_loaded_modules( );
my $okay = defined $modules ? 0 : 1;
ok( $okay, '_get_loaded_modules catches no arguments' );

   $modules = Test::Prereq->_get_loaded_modules( undef, 't' );
$okay = defined $modules ? 0 : 1;
ok( $okay, '_get_loaded_modules catches missing first arg' );

   $modules = Test::Prereq->_get_loaded_modules( 'blib/lib', undef );
$okay = defined $modules ? 0 : 1;
ok( $okay, '_get_loaded_modules catches missing second arg' );

}
