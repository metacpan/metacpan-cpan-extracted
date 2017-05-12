package Test::MockDBI::Base;

use warnings;
use strict;

sub _dbi_errstr{ return shift->{errstr}; }
sub _dbi_err{ return shift->{err}; }

1;