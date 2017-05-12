=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::LoadableClass works with L<Moose>.

=head1 DEPENDENCIES

Requires Moose 2.0000; skipped otherwise.

=head1 AUTHOR

Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Requires { Moose => '2.0000' };
use Test::Fatal;
use Class::Load 'is_class_loaded';

{
	package MyClass;
	use Moose;
	use Types::LoadableClass qw/LoadableClass LoadableRole/;
	
	has foobar_class => (
		is     => 'ro',
		isa    => LoadableClass,
	);
	
	has foobar_role => (
		is     => 'ro',
		isa    => LoadableRole,
	);
}

ok(!is_class_loaded('FooBarTestClass'), 'class is not loaded');
is(
	exception { MyClass->new(foobar_class => 'FooBarTestClass') },
	undef,
	'LoadableClass validates',
);
ok(is_class_loaded('FooBarTestClass'), 'now class is loaded');

like(
	exception { MyClass->new(foobar_class => 'FooBarTestClassDoesNotExist') },
	qr/\AAttribute .?foobar_class.? does not pass the type constraint/,
	'LoadableClass does not validate with another class name',
);

ok(!is_class_loaded('FooBarTestRole'), 'role is not loaded');
is(
	exception { MyClass->new(foobar_role => 'FooBarTestRole') },
	undef,
	'LoadableRole validates',
);
ok(is_class_loaded('FooBarTestRole'), 'now role is loaded');

like(
	exception { MyClass->new(foobar_role => 'FooBarTestClass') },
	qr/\AAttribute .?foobar_role.? does not pass the type constraint/,
	'LoadableRole does not validate with a non-role name',
);

like(
	exception { MyClass->new(foobar_role => 'FooBarTestRoleDoesNotExist') },
	qr/\AAttribute .?foobar_role.? does not pass the type constraint/,
	'and again',
);

use Types::LoadableClass qw/LoadableClass LoadableRole/;

for my $name (qw(Non::Existent::Module ::Syntactically::Invalid::Name)) {
	for my $tc (LoadableClass, LoadableRole) {
		for (0..1)
		{
			is(
				exception { ok(! $tc->check($name), $tc->name . ", $name: validation failed") },
				undef,
				$tc->name . ", $name: does not die"
			);
		}
	}
}

done_testing;
