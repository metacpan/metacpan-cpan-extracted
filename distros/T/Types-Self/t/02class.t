=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::Self works with classes.

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

subtest 'Testing `Self`' => sub {
	package Local::MyClass1;
	use Types::Self;
	my $type = Self;
	my $object = bless {};

	package main;

	is(
		$type->display_name,
		'InstanceOf["Local::MyClass1"]',
		'Type named correctly',
	);

	ok(
		$type->check( $object ),
		'Type seems to work',
	);
};

subtest 'Ensuring nothing else was exported' => sub {
	for my $function ( qw( is_Self assert_Self to_Self ) ) {
		my $coderef = 'Local::MyClass1'->can( $function );
		ok( !$coderef, "$function wasn't exported" );
	}
};

subtest 'Testing other functions' => sub {
	package Local::MyClass2;
	use Types::Self -all;
	my $object = bless {};

	sub from_int {
		my ( $class, $value ) = ( shift, @_ );
		bless { value => $value }, $class;
	}

	use Types::Standard qw( Int ArrayRef );
	coercions_for_Self(
		Int,       \'from_int',
		ArrayRef,  sub { __PACKAGE__->from_int( shift->[0] ) },
	);

	package main;

	ok(
		Local::MyClass2::is_Self( $object )
			&& ! Local::MyClass2::is_Self( [] ),
		'is_Self seems to work',
	);

	ok(
		eval { Local::MyClass2::assert_Self( $object ); 1 }
			&& ! eval { Local::MyClass2::assert_Self( [] ); 1 },
		'assert_Self seems to work',
	);

	my $coerced = Local::MyClass2::to_Self( 42 );
	ok(
		ref($coerced) && $coerced->{value} == 42,
		'to_Self seems to work',
	);

	$coerced = Local::MyClass2::to_Self( [ 666 ] );
	ok(
		ref($coerced) && $coerced->{value} == 666,
		'to_Self seems to work again',
	);
};

done_testing;
