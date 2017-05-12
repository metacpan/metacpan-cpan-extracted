BEGIN {
	require Test::More;
	Test::More::plan(skip_all => 'PPI is not available') unless eval { require PPI; };
}
use Test::More;

use FindBin;
use lib $FindBin::Bin;

$ENV{FILTERED_TEST_TYPE} = 1; # use_ppi => 1
do 'filtered_after_orig.pl';
