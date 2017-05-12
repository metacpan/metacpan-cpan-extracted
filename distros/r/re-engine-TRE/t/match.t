use strict;
use Test::More tests => 6;
use re::engine::TRE;

=head1 DESCRIPTION

The C<$&> (or C<$MATCH>) variable.

=cut

ok "str" =~ /st/;
is($&, 'st');
is($1, undef);

ok "the string" =~ /\(.\{3\}\)/;
is($&, 'the');
is($1, 'the');

