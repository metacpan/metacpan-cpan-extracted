our $tor = new TheOneRing(debug => 1);

#!./bin/perl
use Test::More qw(no_plan);
use Cwd;

BEGIN { use_ok('TheOneRing'); }
require_ok('GeoDB');

our $tmpdir = "/tmp/tor-tmp-git";

our $startingdir = cwd();

system("rm -rf $tmpdir") if (-d "$tmpdir");
mkdir("$tmpdir");
mkdir("$tmpdir/repo");
mkdir("$tmpdir/test");
chdir("$tmpdir/test");
system("git init");
chdir("..");
system("git clone $tmpdir/test test2");
#chdir("test2");
#system("git config branch.master.remote test");
#system("git config branch.master.remote test");
chdir("test");
ok(1, "setup repo");

do "$startingdir/t/common-tests.pl";

