no if $] > 5.018000, warnings => qw(experimental);

use Test::More;
BEGIN {
	$] >= 5.010 or plan skip_all => "test requires Perl >= 5.010";
	$]  < 5.023 or plan skip_all => "test requires Perl < 5.023";
	plan tests => 6;
};

use lexical::underscore;

sub foo {
	my $_ = 101;
	bar();
	is($_, 42);
}

sub bar {
	$_ = 102;
	baz();
}

sub baz {
	my $_ = 103;
	quux();
}

sub quux {
	my $_ = 104;
	
	is(${ lexical::underscore() }, 103);
	is(${ lexical::underscore(-1) }, 104);
	is(${ lexical::underscore(0) }, 103);
	is(${ lexical::underscore(1) }, 102);
	is(${ lexical::underscore(2) }, 101);
	
	${ lexical::underscore(2) } = 42;
}

foo();
