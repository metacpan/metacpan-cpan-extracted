=pod

=encoding utf-8

=head1 PURPOSE

Test Type::Libraries with just L<Types::Standard>.

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
use Test::TypeTiny;

use Type::Libraries [qw(Types::Standard)] => qw(Int);

should_pass(4,   Int);
should_fail(3.9, Int);

done_testing;

