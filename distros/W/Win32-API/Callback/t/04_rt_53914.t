#!perl -w
#
# RT #53914, http://rt.cpan.org/Ticket/Display.html?id=53914
# SetConsoleCtrlHandler callback fails
# http://msdn.microsoft.com/en-us/library/ms685049(v=VS.85).aspx
#
# Test contributed by Reini Urban

use strict;
use warnings;
use Test::More skip_all => 'GenerateConsoleCtrlEvent() crashes consistently. Reason unknown so far.';

use Win32::API;
use Win32::API::Callback;

#BEGIN { $Win32::API::DEBUG = 1; }
#plan tests => 2;

use_ok('Win32::API::Callback');

Win32::API->Import('kernel32', 'SetConsoleCtrlHandler',    'KL', 'L');
Win32::API->Import('kernel32', 'GenerateConsoleCtrlEvent', 'LL', 'L');
Win32::API->Import('kernel32', 'GetLastError',             '',   'L');

sub cb {
    my ($dwCtrlType) = @_;

    open(FILE, '>', 'QUIT.TXT');
    print FILE "RECEIVED SIGNAL: $dwCtrlType\n";
    close FILE;

    return 0;
}

my $callback = Win32::API::Callback->new(\&cb, "L", "L");

SetConsoleCtrlHandler($callback, 1)    # add handler
    or die "Error: " . GetLastError() . "\n";
END { unlink "QUIT.TXT"; }

diag("callback installed, sleep 1, generate Ctrl-C signal");
sleep(1);

#GenerateConsoleCtrlEvent(0, 0); # generate the Ctrl-C signal
GenerateConsoleCtrlEvent(1, 0);        # generate the Ctrl-Break signal
diag("callback called or not");
sleep(2);
ok(-f "QUIT.TXT", "QUIT.TXT exists, ctrl-c signalhandler called");
SetConsoleCtrlHandler($callback, 0);    # remove handler
