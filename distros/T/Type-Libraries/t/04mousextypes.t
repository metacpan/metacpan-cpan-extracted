=pod

=encoding utf-8

=head1 PURPOSE

Test Type::Libraries with L<Types::Standard> and
L<MouseX::Types::Common::Numeric>.

=head1 DEPENDENCIES

Requires L<MouseX::Types::Common::Numeric> 0.001000; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'MouseX::Types::Common::Numeric' => '0.001000' };
use Test::TypeTiny;

use Type::Libraries [qw(
	Types::Standard
	MouseX::Types::Common::Numeric
)] => qw( PositiveInt Int );

should_pass(4,   Int);
should_fail(3.9, Int);

should_pass(4,   PositiveInt);
should_fail(-4,  PositiveInt);

done_testing;

