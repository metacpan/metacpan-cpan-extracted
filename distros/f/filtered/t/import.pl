use Test::More tests => 12;

use FindBin;
use lib "$FindBin::Bin";

my (@arg) = ();
my $USE_PPI;

BEGIN {
	$USE_PPI = eval { require PPI; };
	if($ENV{FILTERED_TEST_TYPE} == 0) {
	} elsif($ENV{FILTERED_TEST_TYPE} == 1) {
		$USE_PPI = 1;
		@arg = (use_ppi => 1);
	} elsif($ENV{FILTERED_TEST_TYPE} == 2) {
		$USE_PPI = 0;
		@arg = (use_ppi => 0);
	}
	my ($arg) = (@arg ? ', '.join(' => ', @arg) : '');
}

package a;

BEGIN { ::use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', on => 'FilterTest', @arg, 'call'); }

# Duplicated use should have no effect
BEGIN { ::use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', on => 'FilterTest', @arg, 'call'); }

# Duplicated use should have no effect
BEGIN { ::use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', @arg, 'FilterTest', 'call'); }

::is(call(), 'BARBARBAR');
::is(FilteredTest::ppi_check(), $USE_PPI ? 'Dummy::FilterTest::Module' : 'Dummy::FilteredTest::Module');
::is(FilteredTest::ppi_check_old(), 'FilteredTest::Module');

package b;

# Different filter should be available
BEGIN { ::use_ok('filtered', by => 'MyFilter2', as => 'FilteredTest2', on => 'FilterTest', @arg, 'call'); }

::is(call(), 'BARFOO');

package c;

# Different target should be available
BEGIN { ::use_ok('filtered', by => 'MyFilter2', as => 'FilteredTest3', on => 'FilterTest2', @arg, 'call'); }

::is(call(), 'BARBAR');

package d;

# Different target should be available
BEGIN { ::use_ok('filtered', by => 'MyFilter2', @arg, 'Test::Test::FilterTest3', 'call'); }

::is(call(), 'BARZOTZOT');
