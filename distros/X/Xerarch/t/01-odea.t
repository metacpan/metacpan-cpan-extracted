use Test::More;

{
	package Test;

	use Xerarch;

	our $OKAY = 'testing';
	our @FOO = ('foo', 'bar');
	our %THING = 'nope' => 1;

	sub new {
		bless {}, $_[0];
	}

	sub one {
		return 1;
	}

	1;
}

my $test = Test->new();
my $methods = $test->xerarch_methods();

is_deeply($methods, ['new', 'one']);

my $scalars = $test->xerarch_scalars();
is_deeply($scalars, ['$OKAY']);

my $arrays = $test->xerarch_arrays();
is_deeply($arrays, ['@FOO']);

my $hashes = $test->xerarch_hashes();
is_deeply($hashes, ['%THING']);

my $glob = $test->xerarch_globs();
is_deeply($glob, []);

done_testing();

