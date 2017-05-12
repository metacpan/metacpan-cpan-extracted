#!perl -T

use strict;
use warnings;
use Test::More tests => 5;
use Win32::PrintBox qw(set_page_size get_page_size);
Win32::PrintBox::init();

############# get_page_size
ok(get_page_size() == 25, 'Get default page size');

############# set_page_size
set_page_size(20);
ok(get_page_size() == 20, 'Set default page size');

############# Existing Shell print
ok(select() eq 'main::STDOUT', 'print not re-directed');

############# Existing Shell warn
my $expected = "OK at -e line 1.";
my $actual = `perl -I./blib/lib -MWin32::PrintBox -e "Win32::PrintBox::init(); warn q[OK]" 2>&1`;
chomp $actual;
ok($actual eq $expected, "warn not re-directed: '$expected', '$actual'");

############# Existing Shell pause
ok(`perl -I./blib/lib -MWin32::PrintBox -e "Win32::PrintBox::init(); print q[OK]` eq 'OK', 'Not Press any key');

