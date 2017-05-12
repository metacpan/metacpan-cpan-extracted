use strict;
use warnings;
use Test::More;
use Test::Proto::Base;
use Test::Proto::Formatter::TestBuilder;

sub p { Test::Proto::Base->new(); }

#~ test by visual inspection till I figure out something better
#~ this script also verifies that the code runs without dying.


my $tbf = Test::Proto::Formatter::TestBuilder->new();
#~ Important to also test results which are constructed via validate first:
$tbf->format(p->false->validate(0)); #~ should print ok, and not die. 

#~ just using ok
p->num_gt(0)->num_lt(10)->ok(1);
# p->num_gt(0)->num_lt(10)->ok(11); #~ if we do this it will cause the test to fail, unfortunately

use Test::Proto::ArrayRef;

Test::Proto::ArrayRef->new->in_groups(2,[['a','b'],['c','d'],['e']])->ok(['a','b','c','d','e'], 'Because...'); #~ print off a sample

done_testing;
