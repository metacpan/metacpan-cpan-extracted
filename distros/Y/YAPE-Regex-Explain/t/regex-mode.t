
use warnings;
use strict;
use Test::More tests => 2;

# Check if module loads ok
BEGIN { use_ok('YAPE::Regex::Explain') }

my $re = 'foo\d+';
my $act = YAPE::Regex::Explain->new($re)->explain('regex');
my $exp = q/(?x-ims:               # group, but do not capture (disregarding
                       # whitespace and comments) (case-sensitive)
                       # (with ^ and $ matching normally) (with . not
                       # matching \n):

  foo                    # 'foo'

  \d+                    # digits (0-9) (1 or more times (matching
                         # the most amount possible))

)                      # end of grouping
/;

# Split into lines, then strip all leading/trailing whitespace
my @exps = split /\n/, $exp;
my @acts = split /\n/, $act;
for (@exps, @acts) { s/^\s+//; s/\s+$// }
is_deeply(\@acts, \@exps, 'regex mode');


