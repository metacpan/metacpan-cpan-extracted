#! perl
use strict;
use warnings;
use Win32;
use Time::HiRes 'sleep';
use Test::More;
use Log::Any::Adapter 'TAP';

use_ok 'Win32::PowerShell::IPC';

my $ps= new_ok( 'Win32::PowerShell::IPC', [], 'IPC instance' );

ok( $ps->start_shell, 'Start child process' );

is( $ps->run_command("echo Foo"), "Foo\r\n", 'Run echo command' );

ok( !$ps->stdout_readable(1), 'No data available on pipe' );

ok( $ps->begin_command("echo Bar"), 'Begin another echo command' );

for (1..10) { last if $ps->stdout_readable(1); sleep .2; }
ok( $ps->stdout_readable(1), 'Data available on pipe' );

ok( $ps->begin_command("echo Baz"), 'begin another echo command' );
is( $ps->collect_command(), "Bar\r\n", 'collect result of first command' );

is( $ps->run_command("echo Blah"), "Blah\r\n", 'Run new command discarding result of previous' );

ok( $ps->terminate_shell, 'Clean terminate' );

# TODO: find a way to test that the powershell process is no longer running

ok( $ps->start_shell, 'Start shell again, for no reason' );
undef $ps; # should not throw exception
pass( 'Shell terminated again, presumably?' );

done_testing;
