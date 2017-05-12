#!/usr/bin/perl
use strict;
use warnings;
use Test; 
BEGIN { plan tests => 3 }
use Win32::SysTray; ok(1);               
use File::Basename;
use File::Spec::Functions qw[ rel2abs ];

my $tray = new Win32::SysTray (
	'icon' => rel2abs(dirname($0)).'\icon.ico',
	'single' => 1,
); ok(2);

$tray->setMenu (
	"> &Test" => sub { print "Hello from the Tray\n"; },
	">-"	  => 0,
	"> E&xit" => sub { return -1 },
); ok(3);

exit;

__END__
