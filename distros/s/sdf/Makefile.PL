
require 5.004;  # make sure perl version is at least 5.004

if (defined $ENV{SDFHOME}) {
	warn <<EOT;

	The environment variable SDFHOME is defined as

		$ENV{SDFHOME}

	Since SDF 2.000, SDF is installed into the perl library
	tree.  Please remove the SDFHOME definition or make
	sure that only your private addition are there.

EOT
}

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'SDF',
	'DISTNAME'	=> 'sdf',
	'VERSION'	=> '2.001beta1',

	'DIR'		=> [ qw(bin perllib) ],

	'dist'          => {'COMPRESS'=>'gzip -9f', 'SUFFIX'=>'.gz'},
	);

package MY;

# What happens when we say 'make test'
# Copied libwww Makefile.PL
sub test
{
    q(
TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}

# Use t/sdftest for test target
#sub test
#{
#    q(
#TEST_VERBOSE=0
#
#test: all
#	cd t && ./sdftest $(FULLPERL)
#
#);
#}

