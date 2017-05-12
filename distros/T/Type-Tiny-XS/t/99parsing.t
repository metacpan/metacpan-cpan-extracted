=pod

=encoding utf-8

=head1 PURPOSE

Parsing edge cases for C<Tuple>.

=head1 DEPENDENCIES

Requires L<Type::Parser>; skipped otherwise.

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
		? plan( tests    => 4 )
		: plan( skip_all => "This test requires Type::Parser" );
}

use_ok('Type::Tiny::XS');

my $expr  = 'Tuple[Int,Map[Int,ArrayRef],Undef]';
my $check = Type::Tiny::XS::get_coderef_for($expr);

is(ref($check), 'CODE', "managed to parse expression '$expr'");

if ($check) {
	ok  $check->([42, {1=>[]}, undef]);
	ok !$check->([42, {1=>undef}, undef]);
}
else {
	fail('cannot run this test') for 1..2;
}
