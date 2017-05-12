#!/usr/bin/perl

use strict;
use Win32::Resources::Update;

unless ($ARGV[1]) {
	print STDERR "Usage: add_xpmanifest.pl file.exe description\n";
	exit(0);
}

my $exe = Win32::Resources::Update->new(filename => $ARGV[0]);
$exe->setXPStyleOn($ARGV[1]);
