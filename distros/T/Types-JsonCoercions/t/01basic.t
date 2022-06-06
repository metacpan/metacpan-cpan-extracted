=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::JsonCoercions works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Standard qw( Int Str Ref ArrayRef HashRef Tuple );
use Types::JsonCoercions -types, -coercions;

is(
	StrJ->assert_coerce( [1] ),
	'[1]',
	'StrJ',
);

is_deeply(
	HashRefJ->assert_coerce( '{"a":1}' ),
	{ a => 1 },
	'HashRefJ',
);

is_deeply(
	ArrayRefJ->assert_coerce( '[1,2,3]' ),
	[1, 2, 3],
	'ArrayRefJ',
);

is_deeply(
	ArrayRefJ->of( Int )->assert_coerce( '[1,2,3]' ),
	[1, 2, 3],
	'ArrayRefJ->of( Int )',
);

is_deeply(
	RefJ->assert_coerce( '{"a":1}' ),
	{ a => 1 },
	'RefJ (1)',
);

is_deeply(
	RefJ->assert_coerce( '[1,2,3]' ),
	[1, 2, 3],
	'RefJ (2)',
);

is(
	Str->plus_coercions( ToJSON )->assert_coerce( [1] ),
	'[1]',
	'Str->plus_coercions( ToJSON )',
);

is_deeply(
	HashRef->plus_coercions( FromJSON )->assert_coerce( '{"a":1}' ),
	{ a => 1 },
	'HashRef->plus_coercions( FromJSON )',
);

is_deeply(
	ArrayRef->plus_coercions( FromJSON )->assert_coerce( '[1,2,3]' ),
	[1, 2, 3],
	'ArrayRef->plus_coercions( FromJSON )',
);

is_deeply(
	Ref->plus_coercions( FromJSON )->assert_coerce( '{"a":1}' ),
	{ a => 1 },
	'Ref->plus_coercions( FromJSON ) (1)',
);

is_deeply(
	Ref->plus_coercions( FromJSON )->assert_coerce( '[1,2,3]' ),
	[1, 2, 3],
	'Ref->plus_coercions( FromJSON ) (2)',
);

is_deeply(
	Tuple->of( Int, Int, Int )->plus_coercions( FromJSON )->assert_coerce( '[1,2,3]' ),
	[1, 2, 3],
	'Tuple->of( Int, Int, Int )->plus_coercions( FromJSON )',
);

done_testing;
