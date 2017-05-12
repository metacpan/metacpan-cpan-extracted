# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Win32::Process::User;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $USER = Win32::Process::User->new();
my %h = $USER->GetByPID($ARGV[0]) if $ARGV[0];
if(!%h) { print " " . $USER->GetError() . "\n"; exit; }
foreach (keys %h)
{
	print "$_=" . $h{$_} . "\n";
}

# 0x0005d120
%h=$USER->GetByName("hamster.exe");
if(!%h) { print " " . $USER->GetError() . "\n"; exit; }
foreach (keys %h)
{
	print "$_=" . $h{$_} . "\n";
}
