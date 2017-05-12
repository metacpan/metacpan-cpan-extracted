=pod

Copy of F<t/eval-comp.t> that tests another callback sub.

=cut

use strict;

use Test::More tests => 1;

use re::engine::Plugin (
    exec => sub { die "died at exec time" },
);

eval { 'oh' =~ /noes/ };
ok index($@ => 'at exec') => 'die in exec works';


