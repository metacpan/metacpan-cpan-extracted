use strict;
use warnings;
use feature "say";
use File::Basename qw<dirname>;

use Test::More tests=>11;

my $dir =dirname __FILE__;

{
	#Tests keeping command line options after processing
	my $fh;
	unless(open $fh, "-|", "perl -I $dir/../lib $dir/01-keep.t.p --test_option 10"){
		die "Could not open sub process";
	}

	my @results=<$fh>;

	my @expected=(10,"--test_option","10");

	ok @results=@expected, "Keep count correct";
	for(0..@expected-1){
		chomp $results[$_];
		ok($results[$_] eq $expected[$_], "Keep as expected");
	}

}
{
	#Tests consuming command line options during processing
	my $fh;
	unless(open $fh, "-|", "perl -I $dir/../lib $dir/01-consume.t.p --test_option 10"){
		die "Could not open sub process";
	}

	my @results=<$fh>;

	my @expected=(10);

	ok @results=@expected, "Consume count correct";
	for(0..@expected-1){
		chomp $results[$_];
		ok($results[$_] eq $expected[$_], "Consume as expected");
	}

}
{
	#Tests sub called mulitple times from command line, synthetically generating different constant names
	my $fh;
	unless(open $fh, "-|", "perl -I $dir/../lib $dir/01-sub.t.p --test_option 10 --test_option 20"){
		die "Could not open sub process";
	}

	my @results=<$fh>;

	my @expected=(10,20);

	ok @results=@expected, "Sub multicall count correct";
	for(0..@expected-1){
		chomp $results[$_];
		ok($results[$_] eq $expected[$_], "Sub as expected");
	}

}
{
	#Tests sub called mulitple times from command line, ensuring the same constant is updated be for
	#being created
	my $fh;
	unless(open $fh, "-|", "perl -I $dir/../lib $dir/01-sub.t.p --test_option 10 --test_option 20"){
		die "Could not open sub process";
	}

	my @results=<$fh>;

	my @expected=(20);

	ok @results=@expected, "Sub value update count correct";
	for(0..@expected-1){
		chomp $results[$_];
		ok($results[$_] eq $expected[$_], "Sub as expected");
	}

}
