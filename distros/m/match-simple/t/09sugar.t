=pod

=encoding utf-8

=head1 PURPOSE

Test that match::simple::sugar works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use match::simple::sugar;

for ( '1.0' ) {
	when numeric 1, then { pass };
	when '1.0', then { fail };
	fail;
}

for ( '1.0' ) {
	when '1.0', then { pass };
	when numeric 1, then { fail };
	fail;
}

for ( '1.0' ) {
	when 1, then { fail };
	when '1.0', then { pass };
	fail;
}

{
	my $e = exception {
		for ( '1.0' ) {
			when 1;
			when '1.0';
		}
	};
	like $e, qr/when: expects then/;
}

done_testing;
