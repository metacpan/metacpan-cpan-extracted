#!/usr/bin/perl

# This script can be run from anywhere, disrespecting cwd, and always will found lib
# for ex:
#	* from current dir:
#		$ perl mytest.pl
#		# mytest use OK from /path/to/lib-abs/examples
#	* from /tmp by absolute path
#		$ perl /path/to/lib-abs/examples/mytest.pl
#		# mytest use OK from /tmp
#	* from /tmp by relative path
#		$ perl ../path/to/lib-abs/examples/mytest.pl
#		# mytest use OK from /tmp

use lib::abs '.';
use mytest;
