=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<AnyOf> and C<AllOf>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require Type::Parser }
		? plan( tests    => 14 )
		: plan( skip_all => "This test requires Type::Parser" );
}

use_ok('Type::Tiny::XS');

{
	my $check = Type::Tiny::XS::get_coderef_for('AnyOf[ArrayRef[Int],HashRef[Int]]');
	
	ok  $check->({})              => 'yes {}';
	ok  $check->([])              => 'yes []';
	ok  $check->([42])            => 'yes [42]';
	ok !$check->(42)              => 'no 42';
	ok !$check->([42,[]])         => 'no [42,[]]';
	ok !$check->({ foo => "y" })  => 'no { foo => "y" }';
	ok !$check->(undef)           => 'no undef';
}

{
	my $check = Type::Tiny::XS::get_coderef_for('AllOf[PositiveInt,Enum[-1,0,1,2]]');
	
	ok !$check->(-1)              => 'no -1';
	ok !$check->(0)               => 'no 0';
	ok  $check->(1)               => 'yes 1';
	ok  $check->(2)               => 'yes 2';
	ok !$check->(3)               => 'no 3';
	ok !$check->(undef)           => 'no undef';
}
