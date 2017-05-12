#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------

use strict;
use warnings;
use Test::More;
use Test::Compile;

#-----------------------------------------------------------------------------

all_non_testsuite_modules();

#-----------------------------------------------------------------------------

sub all_non_testsuite_modules {

	my @modules = grep { $_ !~ m{/TestSuite.pm$} } all_pm_files();
	plan tests => scalar @modules;
	foreach my $module ( @modules ) {
		pm_file_ok
		($module);
	}
	return;
}
