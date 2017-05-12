=head1 PURPOSE

Test that combining traits that shouldn't be combined throws.

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
use Test::Warnings;
use Test::Fatal;

use Tie::Moose;

ok defined exception { Tie::Moose->with_traits(qw/ FallbackSlot FallbackHash /) };
ok defined exception { Tie::Moose->with_traits(qw/ FallbackSlot Forgiving /) };
ok defined exception { Tie::Moose->with_traits(qw/ FallbackHash Forgiving /) };

done_testing;
