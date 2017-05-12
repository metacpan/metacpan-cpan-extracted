#!/usr/bin/perl

# This script can be run from anywhere, disrespecting cwd, and always will found lib
# for ex:
#	* from current dir:
#		$ perl mytest.pl
#		# mytest use OK from /path/to/ex-lib/examples
#	* from /tmp by absolute path
#		$ perl /path/to/ex-lib/examples/mytest.pl
#		# mytest use OK from /tmp
#	* from /tmp by relative path
#		$ perl ../path/to/ex-lib/examples/mytest.pl
#		# mytest use OK from /tmp

use ex::lib '.'; # But better to use lib::abs '.';
use mytest;
