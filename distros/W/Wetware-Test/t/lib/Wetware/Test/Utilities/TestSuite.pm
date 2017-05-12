#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Utilities::TestSuite;

use strict;
use warnings;

use FindBin qw($Bin);
use Test::More;

use base q{Wetware::Test::Class};

our $VERSION = 0.01;

use Wetware::Test::Utilities;

#-----------------------------------------------------------------------------

sub class_under_test { return 'Wetware::Test::Utilities' }

#-----------------------------------------------------------------------------
# This is a fun way to solve the problem of testing a method.
# put the data in an array of hashes.
# I opted for 'want/have' vice 'got/expected' for this test as it
# makes things line up Purty. Your Mileage May Vary....
#
sub test_is_testsuite_module : Test(2) {
	my $self = shift;
		
	my @test_data = (
		{
			label => 'has a TestStuite',
			path  => '/some/path/TestSuite.pm',
			want  => 1,
		},
		{
			label => 'does NOT have a TestStuite',
			path  => '/some/path/JRandom.pm',
			want  => q{},
		},
	);
	
	{
        ## no critic (ProhibitProlongedStrictureOverride)
        no strict qw(refs);       ## no critic (ProhibitNoStrict)
        no warnings qw(redefine); ## no critic (ProhibitNoWarnings)

        my $class = $self->class_under_test();

        # remember pod2usage has been imported in to the class_under_test
        my $method_name = $class . '::readable_file_path';
        local *{$method_name} = sub {  return 'true'; };
        
	
		foreach my $test_case (@test_data) {
			my $have = Wetware::Test::Utilities::is_testsuite_module(
			 $test_case->{'path'});
			Test::More::is($have,  $test_case->{'want'}, $test_case->{'label'});
		}
	
	}
	return $self;
}

sub test_readable_file_path : Test(3) {
	my $self = shift;
	my $got_no_arg_passed = Wetware::Test::Utilities::readable_file_path();
	
	Test::More::ok( ! $got_no_arg_passed, 'readable_file_path() without arg');
	
	my $t_dir = Wetware::Test::Utilities::path_to_data_dir();
	
	my $read_able_file = File::Spec->join($t_dir,'TestSuite.pm');
	
	my $got_readable_file = Wetware::Test::Utilities::readable_file_path($read_able_file);
	
	Test::More::ok( $got_readable_file, 'readable_file_path() withreadable file');
	
	my $no_such_file = File::Spec->join($t_dir,'NoSuchFileHere');
	
	my $got_no_such_file =  Wetware::Test::Utilities::readable_file_path($no_such_file);
	
	Test::More::ok( ! $got_no_such_file, 'readable_file_path() file path does not exist');
	
	
	return $self;
}
#-----------------------------------------------------------------------------

sub test_path_to_data_dir_from : Test(2) {
	my $self = shift;
		
	my @test_data = (
		{
			label => 'path_to_data_dir_from no t/ ',
			path  => '/some/path/here',
			want  => '/some/path/here/test_data',
		},
		{
			label => 'path_to_data_dir_from with t/ in path',
			path  => '/some/path/t/lib/JRandom/TestSuite.pm',
			want  => '/some/path/t/test_data',
		},
	);
	
	foreach my $test_case (@test_data) {
		my $have = Wetware::Test::Utilities::path_to_data_dir_from(
		 $test_case->{'path'});
		Test::More::is($have,  $test_case->{'want'}, $test_case->{'label'});
	}
	return $self;
}

sub test_path_to_data_dir : Test(1) {
	my $self = shift;
	
	( my $t_dir =  $Bin ) =~ s{/t/.*}{/t/};
	my @test_data = (
		{
			label => 'path_to_data_dir',
			want  =>  "${t_dir}/test_data",
		},
	);
	
	foreach my $test_case (@test_data) {
		my $have = Wetware::Test::Utilities::path_to_data_dir();
		Test::More::is($have,  $test_case->{'want'}, $test_case->{'label'});
	}
	return $self;

}
#-----------------------------------------------------------------------------

1;