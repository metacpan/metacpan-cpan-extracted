#!./bin/perl
use Test::More qw(no_plan);
use Cwd;

BEGIN { use_ok('TheOneRing'); }
require_ok('GeoDB');

our $tmpdir = "/tmp/tor-tmp-svk";

our $startingdir = cwd();

system("rm -rf $tmpdir") if (-d "$tmpdir");
mkdir("$tmpdir");
mkdir("$tmpdir/repo");
$ENV{'SVKROOT'}="$tmpdir/repo";
$ENV{'SVKBATCHMODE'} = 1;
system("svk depotmap -i");
system("svk mkdir -m \"initial repo\" //test");
chdir("$tmpdir");
system("svk checkout //test");
system("svk checkout //test test2");
chdir("test");
ok(1, "setup repo");

do "$startingdir/t/common-tests.pl";

