#!/usr/local/bin/perl -w

# this is a little helper program for our testers
# this is not used by the test scripts, but it
# designed to take a single Senseval-2 answer key
# file as input, and then essentially erase the
# answers and replace them with NOTAG. This allows
# for testing of untagged data. 

open(IN,$ARGV[0]);

$k=0;

while(<IN>)
{
	if(/<answer instance=\"(.*)\" senseid=\".*\"\/>/)
	{
		print "<answer instance=\"$1\" senseid=\"NOTAG\"\/>\n";
		next;
	}
	if(/<\/instance>/)
	{
		$k++;
	}
	print;
}
