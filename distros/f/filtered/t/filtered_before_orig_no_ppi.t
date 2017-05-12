use Test::More;

use FindBin;
use lib $FindBin::Bin;

$ENV{FILTERED_TEST_TYPE} = 2; # use_ppi => 0
do 'filtered_before_orig.pl';
