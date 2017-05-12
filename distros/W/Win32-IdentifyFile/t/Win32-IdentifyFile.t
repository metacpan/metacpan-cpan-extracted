# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-IdentifyFile.t'

#########################
use Cwd;
use Win32::IdentifyFile qw(:all);

use Test::More tests => 10;
BEGIN { use_ok('Win32::IdentifyFile') };

#########################

# Sanity check (2)
is($^O, 'MSWin32', 'OS is Windows');

# Prepare for testing
$^E = 0;

# array context
my @info1 = IdentifyFile ('.');
is(0+$^E, 0, 'os error ok') or diag ("$^E: current directory(.)\n");
my @info2 = IdentifyFile (getcwd());
is(0+$^E, 0, 'os error ok') or diag ("$^E: current directory(getcwd)\n");

my $i;

for ($i=1; $i < @info1; $i++) {
   last if $info1[$i] != $info2[$i]
}

is($i, scalar(@info1), 'Loop without error') or diag ("<@info1> <@info2>");

CloseIdentifyFile ();
is(0+$^E, 0, 'os error ok') or diag ("$^E: Close (array)");


# scalar context:
my $info1 = IdentifyFile ('.');
is(0+$^E, 0, 'os error ok') or diag ("$^E: current directory(.)");
my $info2 = IdentifyFile (getcwd());
is(0+$^E, 0, 'os error ok') or diag ("$^E: current directory(getcwd)");

ok($info1 eq $info2, "The directories are the same" ) or diag ("<$info1> <$info2>");

CloseIdentifyFile ();
is(0+$^E, 0, 'os error ok') or diag ("$^E: Close (scalar)");
