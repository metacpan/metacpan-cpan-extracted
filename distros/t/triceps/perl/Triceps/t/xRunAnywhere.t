#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# An example of a script that finds the libraries by a relative path.

use File::Basename;

# This is the magic sequence that adds the relative include paths.
BEGIN {
	my $mypath = dirname($0);
	unshift @INC, "${mypath}/../blib/lib", "${mypath}/../blib/arch";
}

use Triceps;

# Simulate the test output. Can't "use Test" because it would also
# manipulate @INC and break the cleanliness of the experiment.
print "1..1\n";
print "ok 1\n";
exit 0;

