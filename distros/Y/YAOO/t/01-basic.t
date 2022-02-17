use Test::More;

use strict;
use warnings;

{
	package Test;

	use YAOO;

	auto_build;

	has one => ro, isa(hash(a => "b", c => "d", e => [qw/1 2 3/], f => { 1 => { 2 => { 3 => 4 } } }));
	
	has two => rw, isa(array(qw/a b c d/));

	has three => rw, isa(integer);	

	has four => rw, isa(boolean);

	has five => rw, isa(ordered_hash(
		first => 1,
		second => 2,
		third => 3
	));
}

my $test = Test->new(three => 3, four => 1);

is_deeply($test->one->{e}, [qw/1 2 3/]);

is_deeply($test->two, [ qw/a b c d/ ]);

is($test->three, 3);

push @{ $test->one->{e} }, 4;

is_deeply($test->one->{e}, [qw/1 2 3 4/]);

my @ordered = %{$test->five};

is ($ordered[0], 'first');

is ($ordered[-1], 3);

my $test2 = Test->new(three => 4);

is($test->three, 3);

is_deeply($test2->one->{e}, [qw/1 2 3/]);

done_testing();
