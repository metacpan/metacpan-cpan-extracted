#!./bin/perl
use Test::More qw(no_plan);
use Cwd;

BEGIN { use_ok('TheOneRing'); }
require_ok('GeoDB');

our $tmpdir = "/tmp/tor-tmp-svn";
our $repo = "file://localhost$tmpdir/repo";

our $startingdir = cwd();

system("rm -rf $tmpdir") if (-d "$tmpdir");
mkdir("$tmpdir");
mkdir("$tmpdir/repo");
$ENV{'SVNROOT'}="$tmpdir/repo";
system("svnadmin create $tmpdir/repo");
chdir("$tmpdir");
system("svn co $repo foo");
chdir("foo");
mkdir("test");
system("svn add test");
system("svn commit -m \"test dir\" test");
chdir("..");
system("svn checkout $repo/test");
system("svn checkout $repo/test test2");
chdir("test");
ok(1, "setup repo");

do "$startingdir/t/common-tests.pl";

