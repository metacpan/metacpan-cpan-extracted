#!/usr/bin/perl
# generator of the main() functions for the unit test cases
# Use:
#   genmain.pl <testcase.cpp >testcase.main.cpp

print '
#include <utest/Utest.h>

int main(int ac, char **av)
{
	Utest driver(ac, av);

';

while (<STDIN>) {
	if (/^UTESTCASE\s+(\w+)/) {
		print "
	extern Utest::Testcase $1;
	driver.addcase($1, \"$1\");
";
	}
}

print '
	return driver.run();
}
';
