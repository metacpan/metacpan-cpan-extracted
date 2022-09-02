use 5.006; use strict; use warnings;

package Test::Lives;

our $VERSION = '1.003';

use Carp ();
use Test::Builder ();

my $Tester = Test::Builder->new;

sub lives_and (&;$) {
	my ( $code, $name ) = @_;

	my $ok;

	eval {
		local $Carp::Internal{(__PACKAGE__)} = 1;
		$ok = $code->() for $name;
		1;
	} or do {
		my $e = "$@";
		$ok = $Tester->ok( 0, $name );
		$Tester->diag( $e );
	};

	return $ok;
}

sub import {
	my $class = shift;
	do { die "Unknown symbol: $_" if $_ ne 'lives_and' } for @_;
	no strict 'refs';
	*{ caller . '::lives_and' } = \&lives_and;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Lives - decorate tests with a no-exceptions assertion

=head1 SYNOPSIS

 use Test::More;
 use Test::Lives;

 use System::Under::Test 'might_die';

 lives_and { is might_die, 'correct', $_ } 'system under test is correct';

=head1 DESCRIPTION

This module provides only one function, C<lives_and>, which works almost
exactly like the function of the same name in L<Test::Exception>. That is,
it allows you to test things that could (but shouldn't) throw an exception
without having to have
two separate tests with two separate results (and two separate descriptions).

You pass it a block of code to run (which should contain one test assertion)
and a test description to give the assertion inside the block.

The description will be available inside the block in the C<$_> variable.
(This is different from L<Test::Exception>, which employs hacky magic to
relieve you of having to pass the description to the decorated assertion.)

If the block ends up throwing an exception, a test failure will be logged.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
