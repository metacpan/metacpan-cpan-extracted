
use warnings;
use strict;
use Test::More tests => 2;

# Check if module loads ok
BEGIN { use_ok('YAPE::Regex::Explain') }

my $re = 'foo\d+';
my $act = YAPE::Regex::Explain->new($re)->explain('silent');
my $exp = q/(?x-ims:

  foo

  \d+

)
/;

# Split into lines, then strip all leading/trailing whitespace
my @exps = split /\n/, $exp;
my @acts = split /\n/, $act;
for (@exps, @acts) { s/^\s+//; s/\s+$// }
is_deeply(\@acts, \@exps, 'silent mode');


