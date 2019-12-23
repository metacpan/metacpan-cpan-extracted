=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::DualVar compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::TypeTiny;
use Scalar::Util qw( dualvar );
use Types::DualVar;
use Types::Common::Numeric qw( PositiveInt );

my $type = DualVar->numifies_to(PositiveInt);

should_pass(dualvar(2, '-1'), $type);
should_fail(dualvar(0, '666'), $type);
should_fail(42, $type);

done_testing;
