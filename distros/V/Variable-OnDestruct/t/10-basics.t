#!perl -T

use Test::More tests => 5;

use Variable::OnDestruct;
use Symbol qw/gensym/;

sub foo {
}


{
	my $var = 'foo';
	my $sub = sub { $var };

	on_destruct $var, sub { is($_[0], 'foo', "Scalar got destroyed!") };
	on_destruct my @array, sub { pass("Array got destroyed!") };
	on_destruct my %hash, sub { pass("Hash got destroyed!") };
	on_destruct &{ $sub }, sub { pass("Sub got destroyed!" ) };
	on_destruct *{ gensym() }, sub { pass("Glob got destroyed") };
}
