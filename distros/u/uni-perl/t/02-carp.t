#!/usr/bin/env perl

use Test::More tests => 7
	+do { eval { require Test::NoWarnings;Test::NoWarnings->import; 1 } || 0 };
use uni::perl;

ok defined &carp, 'have carp';
ok defined &croak, 'have croak';
ok defined &confess, 'have confess';

eval q{ croak "test ok" };
like $@, qr/^test ok at/, 'croak works';

eval q{ confess "test ok" };
like $@, qr/^test ok at/, 'confess works';

{
	my $warn;
	local $SIG{__WARN__} = sub {$warn = shift};
	eval q{ carp "test 1 ok" };
	like $warn, qr/^test 1 ok at/, 'carp 1 works' or diag $@;
}

{
	my $warn;
	local $SIG{__WARN__} = sub {$warn = shift};
	eval q{ carp "test 2 ok" };
	like $warn, qr/^test 2 ok at/, 'carp 2 works' or diag $@;
}
