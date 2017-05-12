=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::LoadableClass works with a class which clobbers C<$_>.

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
use lib 't/lib';

use Types::LoadableClass qw/ +LoadableClass /;

my $c = is_LoadableClass("ClobberDollarUnderscore");
ok $c;

done_testing;


