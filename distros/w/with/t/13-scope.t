#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

sub bait { ok !$_[0], 'object shouldn\'t be called' }
sub with::Mock::bait { ok $_[1], 'object should be called' }

my $obj = bless {}, 'with::Mock';

sub alpha {
 use with \$obj;
 bait 1;
}

bait 0;

sub beta {
 bait 0;
}

sub main::gamma { bait 0 }
