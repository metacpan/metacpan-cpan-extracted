#!/usr/local/bin/perl

# this is a little helper program that can be used to see how
# numberic data is formatted with various printf settings
# this is not used directly in the test scripts, but we 
# keep it around in the event a tester is curious about formats

# takes in one command line argument, which is a file name
# is intended for use with *.mat files

open(IN,$ARGV[0]);
$l1 = <IN>;
print $l1;

while(<IN>)
{
	@ele=split(/\s+/);
	foreach $entry (@ele)
	{
		printf("%10.7f",$entry);
	}
	print "\n";
}
