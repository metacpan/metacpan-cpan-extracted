#!/usr/bin/perl -w
use strict;

###############################################################################
# This is a special 'test' to clear out the residue from any
# previous tests that were run, prior to running new tests.
#
# Note: this needs to be portable, so we can't use `rm -rf test`.
###############################################################################

use Test::More  tests => 1;
use File::Find;

#----------------------------------------------------------------------------

find( {
	bydepth => 1,
	wanted => sub { if (-d $_) {
				rmdir $_;
			} else {
				1 while unlink $_; 
			}
		       },
	}, 'test') if -d 'test';

rmdir 'test';

ok(!(-d 'test'),"Test directory removed");
