#!perl -w

use strict;

use Test::More tests => 10;

use FindBin qw($Bin);
use lib "$Bin/tlib";

BEGIN{
	unlink "$Bin/tlib/Foo.pmc";
	unlink "$Bin/tlib/Foo/Bar.pmc";

	$ENV{PERL_MACRO_DEBUG} = 1;
}

use macro;

is(macro::->backend, 'macro::filter', 'using macro::filter');

use Foo;
use Foo::Bar;

sub _f{
	'Baz';
}

is Foo::f(), 'Foo::f', 'Foo::f()';
is Foo::g(), 'Foo::g', 'Foo::g()';
is Foo::Bar::f(), 'Foo::Bar::f', 'Foo::Bar::f()';
is Foo::Bar::g(), 'Foo::Bar::g', 'Foo::Bar::g()';

is Foo::h(), 'func', 'lexicality in Foo';
is Foo::Bar::h(), 'func', 'lexicality in Bar';


is Foo::line(), Foo::correct_line(), 'Foo: correct lineno';
is Foo::Bar::line(), Foo::Bar::correct_line(), 'Bar: correct lineno';

is _f(),     'Baz', 'file scoped';

