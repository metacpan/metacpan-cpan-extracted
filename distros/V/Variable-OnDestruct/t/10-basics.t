#!perl

use strict;
use Test::More 0.90;

use Variable::OnDestruct;
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

done_testing;
