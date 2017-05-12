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
		print &ipwhere ('210.0.128.250', $path . '/QQWry.Dat');
		print "\n";
		print ;
		print &ipwhere ('192.168.1.1', $path . '/QQWry.Dat');
		print "\n";
		print ;
		print &ipwhere ('255.255.255.255', $path . '/QQWry.Dat');
		print "\n";
		print ;
		print &ipwhere ('1.1.1.1', $path . '/QQWry.Dat');
		print "\n";
		print ;
		print &ipwhere ('210.0.128.240', $path . '/QQWry.Dat');
		print "\n";
		print ;
		print &ipwhere ('202.165.107.100', $path . '/QQWry.Dat');
		print "\n";
	}
	my $e = Time::HiRes::time ();
	printf ("%.06f\n", $e - $s);
}
