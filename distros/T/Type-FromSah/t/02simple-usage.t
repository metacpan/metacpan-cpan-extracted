=pod

=encoding utf-8

=head1 PURPOSE

Simple usage of Type::FromSah.

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

use Type::FromSah -all;

my $Int = sah2type( [ 'int*' ], name => 'Int' );

subtest "Tests on Int" => sub {
	is( $Int->name, 'Int', 'type name' );
	ok( $Int->check( 42 ), 'value which passes' );
	ok( !$Int->check( {} ), 'value which fails' );
	ok( $Int->can_be_inlined, 'type can be inlined' );
	is_deeply( $Int->{_data_sah}, [ 'int', { req => 1 } ], 'type knows where it came from' );
};

my $SmallInt = $Int->of( min => 1, max => 10 );

subtest "Tests on Int[ min => 1, max => 10 ]" => sub {
	ok( $SmallInt->check( 4 ), 'value which passes' );
	ok( !$SmallInt->check( 42 ), 'value which fails' );
	ok( !$SmallInt->check( {} ), 'value which fails parent' );
	ok( $SmallInt->can_be_inlined, 'type can be inlined' );
	is_deeply( $SmallInt->{_data_sah}, [ 'int', { min => 1, max => 10, req => 1 } ], 'type knows where it came from' );
};

done_testing;

