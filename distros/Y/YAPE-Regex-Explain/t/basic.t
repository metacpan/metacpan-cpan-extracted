
use warnings;
use strict;
use Test::More tests => 3;

# Check if module loads ok
BEGIN { use_ok('YAPE::Regex::Explain') }

# Check module version number
BEGIN { use_ok('YAPE::Regex::Explain', '4.01') }

my $re = 'foo\d+';
my $act = YAPE::Regex::Explain->new($re)->explain();
my $exp = q/The regular expression:

(?-imsx:foo\d+)

matches as follows:

NODE                     EXPLANATION
----------------------------------------------------------------------
(?-imsx:                 group, but do not capture (case-sensitive)
                         (with ^ and $ matching normally) (with . not
                         matching \n) (matching whitespace and #
                         normally):
----------------------------------------------------------------------
  foo                      'foo'
----------------------------------------------------------------------
  \d+                      digits (0-9) (1 or more times (matching
                           the most amount possible))
----------------------------------------------------------------------
)                        end of grouping
----------------------------------------------------------------------
/;

# Split into lines, then strip all leading/trailing whitespace
my @exps = split /\n/, $exp;
my @acts = split /\n/, $act;
for (@exps, @acts) { s/^\s+//; s/\s+$// }
is_deeply(\@acts, \@exps, $re);

