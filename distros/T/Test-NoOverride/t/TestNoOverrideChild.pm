package t::TestNoOverrideChild;
use strict;
use warnings;

use parent 't::TestNoOverrideParent';

sub foo { __PACKAGE__ }

1;
