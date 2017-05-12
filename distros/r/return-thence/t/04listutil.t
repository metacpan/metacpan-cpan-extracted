=head1 PURPOSE

Check that return::thence can return from List::Util::PP blocks.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use if !eval{ require List::Util::PP },
	'Test::More', skip_all => 'need List::Util::PP';

use Test::More;
use return::thence;
use List::Util::PP qw(reduce);

sub zum {
	my $zum = reduce {
		return::thence 0 if $a == 0;
		return::thence 0 if $b == 0;
		$a + $b
	} @_;
	return $zum;
}

is zum(1, 2, 3, 4), 10;
is zum(1, 2, 0, 3, 4), 0;

done_testing;
