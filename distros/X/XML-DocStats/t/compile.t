# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/compile.t'

#########################

use lib qw(t/lib);

use Test;
BEGIN { plan tests => 2 };
use XML::DocStats;
my $parse = XML::DocStats->new;
ok(1); # If we made it this far, we're ok.
ok(ref($parse) eq 'XML::DocStats');

#########################


