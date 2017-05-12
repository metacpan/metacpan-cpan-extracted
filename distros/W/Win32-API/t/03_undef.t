#!perl -w
#
# RT #39730, http://rt.cpan.org/Ticket/Display.html?id=39730
# Test passing APIs undefined values
#

use strict;
use warnings;
use Test::More;

use IPC::Open3 qw(open3);
use Win32::API qw();
use Win32API::File qw(GetOsFHandle INVALID_HANDLE_VALUE);

plan tests => 3;

diag('Win32::API ' . Win32::API->VERSION());

ok( Win32::API->Import(
        'kernel32',
        'BOOL PeekNamedPipe(
            HANDLE hNamedPipe,
            LPVOID lpBuffer,
            DWORD nBufferSize,
            LPDWORD lpBytesRead,
            LPDWORD lpTotalBytesAvail,
            LPDWORD lpBytesLeftThisMessage
        )',
    ),
    'import sample API (PeekNamedPipe)',
);

diag('Import: ' . $^E);

my $pid;
my $success = eval {

    $pid = open3(my $to_child, my $fr_child, undef, qq{"$^X"})
        or die("open3: $!\n");

    (my $fd_pipe = GetOsFHandle($fr_child)) != INVALID_HANDLE_VALUE
        or die("GetOsFHandle: $^E\n");

    PeekNamedPipe($fd_pipe, undef, 0, undef, my $nAvail, undef)
        or die("PeekNamedPipe: $^E\n");

    1;
};

if (!$success) {
    diag($@);
}

# Not very gentle, but closing $to_child and $fr_child don't end it.
ok(kill(KILL => $pid), 'reclaiming child worked');

#diag("kill: $!");

ok($success, '(RT #39730) sample API (PeekNamedPipe) works with undef values');

