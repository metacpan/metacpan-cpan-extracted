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

{
	package Okay;

	use YAOO;

	extends Test;

	has six => rw, isa(string);
}

{
	package Another;

	use YAOO;

	extends Test;

	has seven => rw, isa(string);
}


my $test = Test->new(three => 3, four => 1);

is_deeply($test->one->{e}, [qw/1 2 3/]);

my $okay = Okay->new(six => 'bug exists');

is_deeply($okay->one->{e}, [qw/1 2 3/]);

is_deeply($okay->six, 'bug exists');

my $another = Another->new(seven => "coding can be fun");

is_deeply($another->seven, 'coding can be fun');

done_testing();
