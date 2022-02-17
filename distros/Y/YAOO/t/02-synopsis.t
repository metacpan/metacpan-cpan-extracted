use Test::More;

use strict;
use warnings;

{
	package Synopsis;

	use YAOO;

	auto_build;

	has moon => ro, isa(hash(a => "b", c => "d", e => [qw/1 2 3/], f => { 1 => { 2 => { 3 => 4 } } }));
	
	has stars => rw, isa(array(qw/a b c d/));

	has satelites => rw, isa(integer);	

	has mental => rw, isa(ordered_hash(
		first => 1,
		second => 2,
		third => 3
	));
}

my $test = Synopsis->new(satelites => 5);

is_deeply($test->moon->{e}, [qw/1 2 3/]);

is_deeply($test->stars, [ qw/a b c d/ ]);

is($test->satelites, 5);

push @{ $test->moon->{e} }, 4;

is_deeply($test->moon->{e}, [qw/1 2 3 4/]);

my @ordered = %{$test->mental};

is ($ordered[0], 'first');

is ($ordered[-1], 3);

done_testing();
