### 12-rb-conflict.t --- Check Tree::Range::RB::Conflict methods  -*- Perl -*-

use strict;
use warnings;

use Test::More qw (tests 2);

require_ok ("Tree::Range::RB::Conflict");

can_ok ("Tree::Range::RB::Conflict",
        "new",
        qw (get_range range_free_p range_set),
        "range_set_over",
        qw (range_iter_closure),
        qw (backend),
        qw (cmp_fn value_equal_p_fn leftmost_value),
        qw (min_node max_node),
        qw (put lookup_leq lookup_geq delete));

## Local variables:
## coding: us-ascii
## End:
### 12-rb-conflict.t ends here
