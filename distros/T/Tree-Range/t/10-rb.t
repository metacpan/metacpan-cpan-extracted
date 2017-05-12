### 10-rb.t --- Test cmp-based Tree::Range::RB  -*- Perl -*-

use strict;
use warnings;

use Test::More qw (tests 17);

require_ok ("Tree::Range::RB");

foreach my $m ("new",
               qw (get_range range_free_p),
               qw (range_set range_set_over),
               qw (range_iter_closure),
               qw (backend),
               qw (cmp_fn value_equal_p_fn leftmost_value),
               qw (min_node max_node),
               qw (put lookup_leq lookup_geq delete)) {
    can_ok ("Tree::Range::RB", $m);
}

## Local variables:
## indent-tabs-mode: nil
## End:
### 10-rb.t ends here
