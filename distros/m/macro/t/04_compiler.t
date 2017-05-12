#!perl -w

use strict;

use Test::More tests => 10;

use FindBin qw($Bin);
use lib "$Bin/tlib";

my($pm1, $pm2);
BEGIN{
	$pm1 = "$Bin/tlib/Foo.pmc";
	$pm2 = "$Bin/tlib/Foo/Bar.pmc";

	unlink $pm1;
	unlink $pm2;

	$ENV{PERL_MACRO_DEBUG} = 0;
}
use Fatal qw(unlink);

use macro;
is(macro::->backend, 'macro::compiler', 'using macro::compiler');

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

unlink $pm1;
unlink $pm2;
