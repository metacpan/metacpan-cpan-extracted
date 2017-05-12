#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes;
use getaddress;

my $path = '/home/cnangel/works/getaddress/data';

{
	my $s = Time::HiRes::time ();
	for (1..100)
	{
		print ;
		print &ipwhere ('221.203.140.26', $path . '/QQWry.Dat');
		print "\n";
	}
	my $e = Time::HiRes::time ();
	printf ("%.06f\n", $e - $s);
}
