=pod

This will always die, see L<re::engine::Plugin/comp> for why.

This can be made to live regardless of C<eval> by adding C<| G_EVAL>
to C<call_sv()> in C<Plugin_comp>.

=cut

use strict;

use Test::More skip_all => 'Always dies';

use re::engine::Plugin (
    comp => sub { die "died at comp time" },
);

eval { "str" =~ /noes/ };

TODO: {
    local $TODO = 'passing tests for known bug with how we handle eval';
    pass;
}
