#!perl

use strict;
use warnings;
use Test::More 0.90;

use Variable::OnDestruct qw/on_destruct on_destruct_fifo/;
use Symbol qw/gensym/;

subtest 'Variable types', sub {
	plan(tests => 5);
	my $var = 'foo';
	my $sub = sub { $var };

	on_destruct $var, sub { pass("Scalar got destroyed!") };
	on_destruct my @array, sub { pass("Array got destroyed!") };
	on_destruct my %hash, sub { pass("Hash got destroyed!") };
	on_destruct &{ $sub }, sub { pass("Sub got destroyed!" ) };
	on_destruct *{ gensym() }, sub { pass("Glob got destroyed") };
};

subtest 'Localization', sub {
	my $counter = 0;
	{
		my %hash;
		on_destruct $hash{foo}, sub { $counter++ };
		{
			local $hash{foo};
			is($counter, 0, 'destructor is not triggered on localization');
		}
		is($counter, 0, 'destructor is not triggered on delocalization');
	}
	is($counter, 1, 'destructor is triggered on destruction');
};

subtest 'lifo', sub {
	my $var = 'foo';
	my $counter = 0;
	on_destruct $var, sub { is($counter++, 1, 'first') };
	on_destruct $var, sub { is($counter++, 0, 'second') };
};

subtest 'fifo', sub {
	my $var = 'foo';
	my $counter = 0;
	on_destruct_fifo $var, sub { is($counter++, 0, 'first') };
	on_destruct_fifo $var, sub { is($counter++, 1, 'second') };
};

done_testing;
