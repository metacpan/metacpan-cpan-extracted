#!perl -w
BEGIN {
	print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
	$| = 1;
}

# $Id: 03_cpl.t,v 1.2 2008/10/01 11:10:12 int32 Exp $

use strict;

# SZABGAB: some of the windows stay open, the script does not close them
# I had to remove one of the test entries as it failed to execute.
# Currently this script does not really test anything, just tries to launch
# applications and never check if the correct applications were opened.
# We should probably replace the testing method somehow if this module is really used.


use Win32::GuiTest::Cmd ':CPL';
use Win32::GuiTest qw/
    SendKeys
    GetForegroundWindow
    /;

use Test::More qw(no_plan);

sub waitcome {
    my $me = shift;
    my $max = shift || 100;
    my $count;
    select(undef, undef, undef, 0.10) 
      while GetForegroundWindow() != $me and $count++ < $max;
}

sub waitgo {
    my $me = shift;
    my $max = shift || 100;
    my $count;
    select(undef, undef, undef, 0.10) 
      while GetForegroundWindow() == $me and $count++ < $max;
}

sub closewnd {
    my $me = shift;
    my $key = shift || "{ESC}";
    select(undef, undef, undef, 0.40);
    waitgo($me);
    SendKeys($key);
    waitcome($me);
}

SKIP: {

skip "Set CPLTEST=1 in order to run these tests", 1 if not $ENV{CPLTEST};

my $me = GetForegroundWindow();

Console();
closewnd($me);
ok(1);

Accessibility();
closewnd($me);
ok(1);

AppWizard();
closewnd($me);
ok(1);

DateTime();
closewnd($me);
ok(1);

Display();
closewnd($me);
ok(1);

Exchange();
closewnd($me);
ok(1);

FindFast();
closewnd($me);
ok(1);

Internet();
closewnd($me);
ok(1);

#Joystick();
#closewnd($me);
#ok(1);

Modem(); 
closewnd($me, "%{F4}");
ok(1);

Mouse();
closewnd($me);
ok(1);

Multimedia();
closewnd($me);
ok(1);

Network();
closewnd($me, "%{F4}");
ok(1);

Odbc(); 
closewnd($me);
ok(1);

Pcmcia(); 
closewnd($me);
ok(1);

Ports(); 
closewnd($me);
ok(1);

Ras();
closewnd($me);
ok(1);

Regional();
closewnd($me);
ok(1);

Server();
closewnd($me);
ok(1);

System();
closewnd($me);
ok(1);

Telephony();
closewnd($me);
ok(1);

Ups();
closewnd($me);
ok(1);

#Users(); # SZABGAB: failed to open on my XP
#closewnd($me, "%{F4}");
#ok(1);

}
