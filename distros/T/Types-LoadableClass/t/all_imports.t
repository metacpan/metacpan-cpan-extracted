=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::LoadableClass exports the right functions.

=head1 AUTHOR

Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::LoadableClass -all;

foreach my $prefix ('is_', 'to_', '') {
	foreach my $name (qw/LoadableClass ModuleName LoadableRole/) {
		my $thing = $prefix . $name;
		ok __PACKAGE__->can($thing), "Exports $thing";
	}
}

done_testing;
