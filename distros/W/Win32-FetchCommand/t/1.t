# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-FetchCommand.t'

#########################

use Config;

use Test::More tests => 19;

BEGIN { use_ok('Win32::FetchCommand') };

#########################

# Sanity check
is($^O, 'MSWin32', 'OS is Windows');

# The only appln we can be certain of is perl!
$^E = 0;
my @Cmd = FetchCommand ('config.pl');
ok(!$^E, 'os ext.error ok');

# Tests changed for v.0.04 (Strawberry Perl)
ok(@Cmd == 2 || (@Cmd == 3 && $Cmd[1] eq '-f'), 'check number of elements(a)');
is($Cmd[0], $Config{'perlpath'},'ext .pl perl path check');
is($Cmd[-1], 'config.pl') or diag ("\@Cmd: <@Cmd>");

@Cmd = FetchCommand ('perl');
is(0+$^E, 0, 'os error ok(perl)') or diag ("$^E: \@Cmd is: @Cmd\n");
ok(@Cmd == 0, 'check number of elements(perl)');

@Cmd = FetchCommand ('test.txt');
is(0+$^E, 0, 'os error ok(test.txt)') or diag ("$^E: \@Cmd is: @Cmd\n");

# Invalid extension 
@Cmd = FetchCommand ('somefile.xdottyx');
ok($^E, 'os ext.error ok(somefile.xdottyx)');
ok(@Cmd == 0, 'check number of elements(somefile.xdottyx)');

# Empty extension 
@Cmd = FetchCommand ('fred.');
ok($^E, 'os ext.error ok(e)');
ok(@Cmd == 0, 'check number of elements(e)');

# Empty filename and extension 
@Cmd = FetchCommand ('.');
ok($^E, 'os ext.error ok(f)');
ok(@Cmd == 0, 'check number of elements(f)');

# print test
my $Exe;
($Exe, @Cmd) = FetchCommand('classes.txt', 'print');
ok(@Cmd == 2, 'check number of elements(g)');
ok($Exe, 'check there is a program for print');

# no 'print' for perl
($Exe, @Cmd) = FetchCommand('thingy.pl', 'print');
ok(@Cmd == 0, 'check number of elements(h)');
is($Exe, undef, 'check there is no program for print');

#use Win32::Process;

#Win32::Process::Create($Obj, $Exe, "@Cmd", 0, NORMAL_PRIORITY_CLASS, ".");
#Win32::Process::Create($Obj, $Exe, "$Exe @Cmd", 0, NORMAL_PRIORITY_CLASS, ".");

