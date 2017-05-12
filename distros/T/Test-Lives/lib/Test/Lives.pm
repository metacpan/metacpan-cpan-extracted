use 5.006;
use strict;
use warnings;

package Test::Lives;
$Test::Lives::VERSION = '1.001';
# ABSTRACT: the 1UP approach to testing exceptional code

use Exporter::Tidy default => [ qw( lives_and ) ];
use Test::Builder ();

my $Tester = Test::Builder->new;
*Level = \$Test::Builder::Level;

sub lives_and (&;$) {
	my ( $code, $name ) = @_;

	local our $Level = $Level + 1; # this function

	my $ok;

	eval {
		local $Level = $Level + 2; # eval block + callback
		$ok = $code->() for $name;
		1;
	} or do {
		my $e = "$@";
		$ok = $Tester->ok( 0, $name );
		$Tester->diag( $e );
	};

	return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Lives - the 1UP approach to testing exceptional code

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use Test::More;
 use Test::Lives;

 use System::Under::Test 'might_die';

 lives_and { is might_die, 'correct', $_ } 'system under test is correct';

=head1 DESCRIPTION

This module provides only one function, C<lives_and>, which allows you to test
things that could (but shouldn't) throw an exception, without having to have
two separate tests with two separate results (and two separate descriptions).

You pass it a block of code to run (which should contain one test assertion)
and a test description to give the assertion inside the block.

The description will be available inside the block in the C<$_> variable.

If the block ends up throwing an exception, a test failure will be logged.

=head1 BUGS AND LIMITATIONS

Currently this module is written against the traditional, singleton-based
Test::Builder design only. It should also have an implementation appropriate
for newer Test::Builder versions, and pick between them at runtime. But that
is not yet implemented.

=head1 SEE ALSO

=over 4

=item * L<Test::Exception>

The original perpetrator of the C<lives_and> design as an assertion decorator.
Unfortunately it has grown several questionable dependencies.

=item * L<Test::Fatal>

Recommended for any exception-related testing needs beyond C<lives_and>.

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
