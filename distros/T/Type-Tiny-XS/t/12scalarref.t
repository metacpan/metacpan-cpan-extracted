=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny::XS's ScalarRef implementation supports references to references.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 9;

use_ok('Type::Tiny::XS');

my $checker = Type::Tiny::XS::get_coderef_for('ScalarRef');

for my $thingy ( "hi", 123, [], {}, sub {}, \1, \*STDOUT, \undef ) {
	my $ref = \$thingy;
	ok $checker->( $ref );
}

done_testing;
