package t::TestNoOverrideNew;
use strict;
use warnings;

use parent 't::TestNoOverrideParent';

sub new { 1 }

sub foo { __PACKAGE__ }

1;
