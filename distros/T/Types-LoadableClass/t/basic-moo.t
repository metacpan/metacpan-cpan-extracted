=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::LoadableClass works with L<Moo>.

=head1 DEPENDENCIES

Requires Moo 1.000000; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on a test by Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This software is copyright (c) 2010 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Requires { Moo => '1.000000' };
use Test::Fatal;
use Class::Load 'is_class_loaded';

{
	package MyClass;
	use Moo;
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

ok(!is_class_loaded('FooBarTestClassMoo'), 'class is not loaded');
is(
	exception { MyClass->new(foobar_class => 'FooBarTestClassMoo') },
	undef,
	'LoadableClass validates',
);
ok(is_class_loaded('FooBarTestClassMoo'), 'now class is loaded');

like(
	exception { MyClass->new(foobar_class => 'FooBarTestClassDoesNotExist') },
	qr/could not be loaded/,
	'LoadableClass does not validate with another class name',
);

ok(!is_class_loaded('FooBarTestRoleMoo'), 'role is not loaded');
is(
	exception { MyClass->new(foobar_role => 'FooBarTestRoleMoo') },
	undef,
	'LoadableRole validates',
);
ok(is_class_loaded('FooBarTestRoleMoo'), 'now role is loaded');

like(
	exception { MyClass->new(foobar_role => 'FooBarTestClassMoo') },
	qr/is not a loadable role/,
	'LoadableRole does not validate with a non-role name',
);

like(
	exception { MyClass->new(foobar_role => 'FooBarTestRoleDoesNotExist') },
	qr/could not be loaded/,
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
