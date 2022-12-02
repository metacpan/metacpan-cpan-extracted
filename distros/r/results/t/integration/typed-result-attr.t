=pod

=encoding utf-8

=head1 PURPOSE

Tests for the typed version of the C<< :Result >> attribute.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $ENV{PERL_STRICT} = 1 };

use Test2::V0;
use Test2::Require::Module 'Type::Utils';
use Data::Dumper;

use results ();

sub foobar : Result(Int) {
	my $in = shift;
	if ( $in > 0 ) {
		return results::ok( $in );
	}
	if ( $in < 0 ) {
		return results::err( $in );
	}
	return 0;  # BAD
}

is( foobar(2)->unwrap, 2 );
is( foobar(-3)->unwrap_err, -3 );

my $e = dies { foobar(0) };
like( $e, qr/^Function 'foobar' declared to return a Result, but returned: 0/ );

like( foobar({})->unwrap_err, qr/did not pass type constraint/ );

done_testing;
