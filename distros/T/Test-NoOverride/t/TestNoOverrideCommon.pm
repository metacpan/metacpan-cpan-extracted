package t::TestNoOverrideCommon;
use strict;
use warnings;

use parent 't::TestNoOverrideParent';

sub parent { __PACKAGE__ }

1;
