### 24-rb-conflict-cmp.t --- Test Tree::Range::RB::Conflict (cmp)  -*- Perl -*-

use strict;
use warnings;

use Test::Fatal qw (exception lives_ok);
use Test::More  qw (tests 13);

require_ok ("Tree::Range::RB::Conflict");

sub cmp {
    ## .
    $_[0] cmp $_[1];
}

my ($cmp, $leftmost)
    = (\&cmp, [ "*leftmost*" ]);
my $rat_options = {
    "cmp"       => $cmp,
    "leftmost"  => $leftmost
};
my $rat
    = new_ok ("Tree::Range::RB::Conflict", [ $rat_options ],
              "Tree::RB-based range tree, overwrite-protected");

isa_ok ($rat->backend (), "Tree::RB",
        "associated backend tree object");
is ($rat->cmp_fn, $cmp,
    "associated comparison function");
is ($rat->leftmost_value, $leftmost,
    "associated leftmost value");

is_deeply ([ $rat->get_range ("cherry") ],
           [ $leftmost ],
           "unbounded range retrieved from the still empty range tree");

ok ($rat->range_free_p ("almond", "strawberry"),
    "range (almond to strawberry) is free in the still empty range tree");

lives_ok { $rat->range_set (qw (blackcurrant cherry 4)); }
         ("associating the (blackcurrant to cherry) range");
lives_ok { $rat->range_set (qw (appricot banana 5)); }
         ("associating the (appricot to banana) range");
like (exception {
          $rat->range_set       (qw (banana cherry X));
      },
      qr (already associated),
      "attempt to associate (banana to cherry) fails");
is_deeply ([ $rat->get_range ("banana") ],
           [ $leftmost, qw (banana blackcurrant) ],
           "read the (banana to blackcurrant) association back");
lives_ok { $rat->range_set_over (qw (banana cherry 6)); }
         ("forcing the (banana to cherry) association");
is_deeply ([ $rat->get_range ("blackcurrant") ],
           [ qw (6 banana cherry) ],
           "read the (banana to cherry) association back");

## Local variables:
## coding: us-ascii
## End:
### 24-rb-conflict-cmp.t ends here
