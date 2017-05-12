=pod

=encoding utf-8

=head1 PURPOSE

Test that L<Types::ReadOnly> works with L<Type::Params>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008;
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

use Types::Standard -types, 'slurpy';
use Types::ReadOnly -types;
use Type::Params 'compile';

my $check;
sub foo {
	$check ||= compile(
		Str,
		slurpy Locked[
			Dict[
				bar => Int,
				baz => Optional[Int],
			],
		],
	);
	my ($key, $hash) = $check->(@_);
	return $hash->{$key};
}

is(
	foo("bar", bar => 42, baz => 666),
	42,
);

is(
	foo("baz", bar => 42, baz => 666),
	666,
);

is(
	foo("baz", bar => 42),
	undef,
);

like(
	exception { foo("blam", bar => 42, baz => 666) },
	qr{^Attempt to access disallowed key 'blam' in a restricted hash},
);

like(
	exception { foo("blam", bar => 42, baz => 666, blam => 999) },
	qr{^Hash has key 'blam' which is not in the new key set},
);

done_testing;

