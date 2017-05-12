use Test::More tests => 25;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin";

my (@arg) = ();
my ($USE_PPI, $arg);

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
	$arg = @arg ? ', '.join(' => ', @arg) : '';
}

BEGIN { use_ok('FilterTest'); }
BEGIN { use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', on => 'FilterTest', @arg); }

# Duplicated use should have no effect
BEGIN { use_ok('FilterTest'); }
BEGIN { use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', on => 'FilterTest', @arg); }

# Duplicated use should have no effect
BEGIN { use_ok('FilterTest'); }
BEGIN { use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', @arg, 'FilterTest'); }

BEGIN { throws_ok { die $@ if ! defined eval 'use NotExistentFilterTest'; } qr/Can't locate .* in \@INC/, 'Not-existent module' }
BEGIN { throws_ok { die $@ if ! defined eval "use filtered by => 'MyFilter'$arg, 'NotExistentFilterTest'"; } qr/Can't find .* in \@INC/, 'Not-existent module' }

BEGIN { throws_ok { die $@ if ! defined eval "use filtered by => 'NotExistentMyFilter'$arg, 'FilterTest'"; } qr/Can't load /, 'Not-existent filter' }

# Different filter should be available
BEGIN { use_ok('FilterTest'); }
BEGIN { use_ok('filtered', by => 'MyFilter2', as => 'FilteredTest2', on => 'FilterTest', @arg); }

# Different target should be available
BEGIN { use_ok('FilterTest2'); }
BEGIN { use_ok('filtered', by => 'MyFilter2', as => 'FilteredTest3', on => 'FilterTest2', @arg); }

# Different target should be available
BEGIN { use_ok('filtered', by => 'MyFilter2', @arg, 'Test::Test::FilterTest3'); }

BEGIN { use_ok('FilterTest'); }
BEGIN { use_ok('filtered', by => 'MyFilter3', as => 'FilteredTest4', with => 'sub { s/FOO/BAR/g }', on => 'FilterTest', @arg); }

is(FilterTest::call(), 'FOOFOOFOO');
is(FilteredTest::call(), 'BARBARBAR');
is(FilteredTest::ppi_check(), $USE_PPI ? 'Dummy::FilterTest::Module' : 'Dummy::FilteredTest::Module');
is(FilteredTest::ppi_check_old(), 'FilteredTest::Module');
is(FilteredTest2::call(), 'BARFOO');
is(FilterTest2::call(), 'FOOFOOFOOFOO');
is(FilteredTest3::call(), 'BARBAR');
is(Test::Test::FilterTest3::call(), 'BARZOTZOT');
is(FilteredTest4::call(), 'BARBARBAR');
