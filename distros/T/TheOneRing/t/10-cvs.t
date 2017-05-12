#!./bin/perl
use Test::More qw(no_plan);
use Cwd;

BEGIN { use_ok('TheOneRing'); }
require_ok('GeoDB');

my $tmpdir = "/tmp/tor-tmp-cvs";

my $startingdir = cwd();

system("rm -rf $tmpdir") if (-d "$tmpdir");
mkdir("$tmpdir");
mkdir("$tmpdir/repo");
$ENV{'CVSROOT'}="$tmpdir/repo";
system("cvs init");
mkdir("$tmpdir/starter");
chdir("$tmpdir/starter");
system("cvs import -m \"initial import\" test TOR T-00");
chdir("..");
system("cvs checkout test");
system("cvs checkout -d test2 test");
chdir("test");
ok(1, "setup repo");

do "$startingdir/t/common-tests.pl";

