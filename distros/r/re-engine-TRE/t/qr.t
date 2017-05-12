use strict;
use Test::More tests => 2;
use re::engine::TRE;

=head1 DESCRIPTION

Test the C<qr//> op.

=cut

my $re = qr/\(a\)/;

ok "a" =~ $re;
is $1, "a";



