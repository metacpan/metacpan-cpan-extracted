=head1 PURPOSE

Check that return::thence can return from Try::Tiny blocks.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use Test::More;

use return::thence;
use Try::Tiny;

# will return 99
sub foo {
	try { return(42) };
	return 99;
}

# will return 42
sub bar {
	try { return::thence(42) };
	return 99;
}

# will return 42
sub baz {
	try   { die; return::thence(42) }
	catch {      return::thence(101) };
	return 99;
}

is foo(), 99;
is bar(), 42;
is baz(), 101;

done_testing;
