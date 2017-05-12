# There is no lexical underscore on Perl 5.8 but the module
# should fall back to the global underscore.
#

use Test::More;
BEGIN {
	plan tests => 6;
};

use lexical::underscore;

sub foo {
	$_ = 101;
	bar();
	is($_, 42);
}

sub bar {
	$_ = 102;
	baz();
}

sub baz {
	$_ = 103;
	quux();
}

sub quux {
	$_ = 104;
	
	is(${ lexical::underscore() }, 104);
	is(${ lexical::underscore(-1) }, 104);
	is(${ lexical::underscore(0) }, 104);
	is(${ lexical::underscore(1) }, 104);
	is(${ lexical::underscore(2) }, 104);
	
	${ lexical::underscore(2) } = 42;
}

foo();
