=pod

=encoding utf-8

=head1 PURPOSE

Test that unhandled results throw an error if they get destroyed.

Note that current versions of Perl demote exceptions thrown in
DESTROY to mere warnings.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test2::V0;

use results ();

sub foo {
	return results::ok(42);
}

sub bar {
	# The result returned by foo() is never handled.
	my $got = foo();
	return 99;
}

my $exception;
{
	local $SIG{__WARN__} = sub { $exception = shift };
	eval { bar() };
}

like $exception, qr/ok.42. went out of scope without being unwrapped/;

done_testing;

