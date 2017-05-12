BEGIN {
	require Test::More;
	Test::More::plan(skip_all => 'Filter::tee is not available') unless eval { require Filter::tee; };
}
use Test::More tests => 10;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin";

use File::Temp;

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

my $tempdir;
BEGIN {
	$tempdir = File::Temp->newdir;
	$ENV{FILTERED_ROOT} = $tempdir->dirname;
}

BEGIN { use_ok('filtered', by => 'MyFilter', as => 'FilteredTest', on => 'FilterTest', @arg); }

# Different filter should be available
BEGIN { use_ok('filtered', by => 'MyFilter2', as => 'FilteredTest2', on => 'FilterTest', @arg); }

# Different target should be available
BEGIN { use_ok('filtered', by => 'MyFilter2', as => 'FilteredTest3', on => 'FilterTest2', @arg); }

# Different target should be available
BEGIN { use_ok('filtered', by => 'MyFilter2', @arg, 'Test::Test::FilterTest3'); }

BEGIN { use_ok('filtered', by => 'MyFilter3', as => 'FilteredTest4', with => 'sub { s/FOO/BAR/g }', on => 'FilterTest', @arg); }

sub check
{
	my ($file, $expected) = @_;

	my $got;
	local $/;
	open my $fh, '<', $file;
	$got = <$fh>;

	is($got, $expected);
}

sub check1
{
	my ($file, $package, $package_, $str) = @_;
	check($file, <<EOF);
package ${package};

use strict;

require Exporter;
our (\@ISA) = qw(Exporter);
our (\@EXPORT_OK) = qw(call);

sub call
{
    return '$str';
}

sub ppi_check
{
    return 'Dummy::${package_}::Module';
}

sub ppi_check_old
{
    return '${package}::Module';
}

1;
EOF
}

check1($tempdir->dirname.'/FilteredTest.pm',  'FilteredTest',  $USE_PPI ? 'FilterTest' : 'FilteredTest',  'BARBARBAR');
check1($tempdir->dirname.'/FilteredTest2.pm', 'FilteredTest2', $USE_PPI ? 'FilterTest' : 'FilteredTest2', 'BARFOO');
check1($tempdir->dirname.'/FilteredTest4.pm', 'FilteredTest4', $USE_PPI ? 'FilterTest' : 'FilteredTest4', 'BARBARBAR');

sub check2
{
	my ($file, $package, $str) = @_;
	check($file, <<EOF);
package ${package}::internal;

sub call
{
	return '${str}';
}

package ${package};

use strict;

require Exporter;
our (\@ISA) = qw(Exporter);
our (\@EXPORT_OK) = qw(call);

sub call
{
    return ${package}::internal::call();
}

1;
EOF
}

check2($tempdir->dirname.'/FilteredTest3.pm', 'FilteredTest3', 'BARBAR');

sub check3
{
	my ($file) = @_;
	check($file, <<EOF);
package Test::Test::FilterTest3;

use strict;

require Exporter;
our (\@ISA) = qw(Exporter);
our (\@EXPORT_OK) = qw(call);

sub call
{
    return 'BARZOTZOT';
}

1;
EOF
}

check3($tempdir->dirname.'/Test/Test/FilterTest3.pm');
