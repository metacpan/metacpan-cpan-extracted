#!perl -w

use strict;

use Test::More tests => 10;
use Test::Warn;

use macro::filter foo => sub{ 'foo' . $_[0] };

warning_like{
	eval q{ use macro foo => undef };
} qr/Illigal declaration/, 'Illigal declaration';

warning_like{
	eval q{ use macro undef() => sub{ 'foo' } };
} qr/Illigal declaration/, 'Illigal declaration';

warning_like{
	eval q{ use macro foo => sub{ 'FOO' }, foo => sub{ 'BAR' }; };
} qr/redefined/, 'Macro redefined';

warning_like{
	eval q{ use macro bar => sub($){ 'bar' } };
} qr/Subroutine prototype .+ ignored/, 'No prototypes';

warning_like{
	eval q{ use macro bar => sub :lvalue{ my $foo } };
} qr/Subroutine attribute .+ ignored/, 'No attributes';

my $result;
warnings_like{
	$result = foo();
} qr/Use of uninitialized value/, 'Not enough arguments';
is $result, 'foo', 'undef used';


ok !eval q{ use macro foo => \&no_such_subroutine; 1 }, 'undefined subroutine';
ok !eval q{ use macro foo => \&UNIVERSAL::isa; 1 },     'XSUB';

is foo('bar'), 'foobar', 'finished';

