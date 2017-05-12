use Test::Most tests => 2;

BEGIN: {
	use_ok( 'Test::Pcuke' );
}

my $runner;

# With undefined config should give a hint "No features"
$runner = Test::Pcuke->new();
isa_ok( $runner, 'Test::Pcuke', 'runner');
