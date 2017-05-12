use Test::More 'no_plan' ;
use Test::Script;


#my $version = '5.01000';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? '../script' : 'script';
my @scripts =  <$dir/*\.pl>;

eval 'use Test::Script;1';


SKIP: {
	skip 'Test::Script not installed', 2  if $@;
	if ( @scripts ) {
		script_compiles  $_    for @scripts;
		script_runs      $_    for @scripts;
		done_testing  scalar 2*@scripts  ;
	}else{
		ok( 1, 'no scripts'), done_testing( 1 ), exit 0    
	}
}
