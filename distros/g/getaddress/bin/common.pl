#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes;

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

sub ipwhere
{
	my $host = shift;
	my ($ip, $port) = split /:/, $host;
	my @ip = split(/\./, $ip);
	my $ipNum = $ip[0] * 16777216 + $ip[1] * 65536+ $ip[2] * 256 + $ip[3];

	my $ipfile = shift;
	$ipfile = "data/QQWry.Dat" unless ($ipfile);
	return "未知地区" unless (-e $ipfile);

	open(FILE, "$ipfile");
	binmode(FILE);
	sysread(FILE, my $ipbegin, 4);
	sysread(FILE, my $ipend, 4);
	$ipbegin = unpack("L", $ipbegin);
	$ipend = unpack("L", $ipend);
	my $ipAllNum = ($ipend - $ipbegin) / 7 + 1;

	my $BeginNum = 0;
	my $EndNum = $ipAllNum;

	my $iptime = 0;
	my ($ipAddr1, $ipAddr2, $ip1num, $ip2num);
	$ip1num = $ip2num = 0;
	while ($ip1num > $ipNum || $ip2num < $ipNum)
	{
		$iptime++;
		last if ($iptime > 100);
		my $Middle = int(($EndNum + $BeginNum) / 2);

		seek(FILE, $ipbegin + 7 * $Middle, 0);
		read(FILE, my $ipData1, 4);
		$ip1num = unpack("L", $ipData1);
		if ($ip1num > $ipNum)
		{
			$EndNum = $Middle;
			next;
		}

		read(FILE, my $DataSeek, 3);
		$DataSeek = unpack("L", $DataSeek."\0");
		seek(FILE, $DataSeek, 0);
		read(FILE, my $ipData2, 4);
		$ip2num = unpack("L", $ipData2);
		if ($ip2num < $ipNum)
		{
			return '未知地区' if ($Middle == $BeginNum);
			$BeginNum = $Middle;
		}
	}

	$/ = "\0";
	read(FILE, my $ipFlag, 1);
	if ($ipFlag eq "\1")
	{
		my $ipSeek;
		read(FILE, $ipSeek, 3);
		$ipSeek = unpack("L", $ipSeek."\0");
		seek(FILE, $ipSeek, 0);
		read(FILE, $ipFlag, 1);
	}
	if ($ipFlag eq "\2")
	{
		my $AddrSeek;
		read(FILE, $AddrSeek, 3);
		read(FILE, $ipFlag, 1);
		if ($ipFlag eq "\2")
		{
			my $AddrSeek2;
			read(FILE, $AddrSeek2, 3);
			$AddrSeek2 = unpack("L", $AddrSeek2."\0");
			seek(FILE, $AddrSeek2, 0);
		}
		else
		{
			seek(FILE, -1, 1);
		}
		$ipAddr2 = <FILE>;
		$AddrSeek = unpack("L", $AddrSeek."\0");
		seek(FILE, $AddrSeek, 0);
		$ipAddr1 = <FILE>;
	}
	else
	{
		seek(FILE, -1, 1);
		$ipAddr1 = <FILE>;
		read(FILE, $ipFlag, 1);
		if($ipFlag eq "\2")
		{
			my $AddrSeek2;
			read(FILE, $AddrSeek2, 3);
			$AddrSeek2 = unpack("L", $AddrSeek2."\0");
			seek(FILE, $AddrSeek2, 0);
		}
		else
		{
			seek(FILE, -1, 1);
		}
		$ipAddr2 = <FILE>;
	}

	chomp($ipAddr1, $ipAddr2);
	$/ = "\n";
	close(FILE);

	$ipAddr2 = '' if ($ipAddr2 =~ /http/i);
	my $ipaddr = "$ipAddr1 $ipAddr2";
	$ipaddr =~ s/CZ88\.NET//ig;
	$ipaddr =~ s/^\s*//g;
	$ipaddr =~ s/\s*$//g;
	$ipaddr = '未知地区' if ($ipaddr =~ /未知|http/i || $ipaddr eq '');
	return $ipaddr;
}

