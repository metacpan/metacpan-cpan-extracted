BEGIN {
    print "1..7\n";
}

use FindBin qw($Bin);
use File::Spec;

package main;

use rlib;

BEGIN {
    print "not " unless $INC[0] eq File::Spec->catdir($Bin,"../lib");
    print "ok 1\n";

    print "not " unless $INC[1] eq File::Spec->catdir($Bin,"lib");
    print "ok 2\n";
}

use rlib qw(dir);

BEGIN {
    print "not " unless $INC[0] eq File::Spec->catdir($Bin,"dir");
    print "ok 3\n";
}

package One;

use Cwd qw(getcwd);
use rlib;

BEGIN {
    my $cwd = getcwd();

    print "not " unless $INC[0] eq File::Spec->catdir($cwd,"t","../lib");
    print "ok 4\n";

    print "not " unless $INC[1] eq File::Spec->catdir($cwd,"t","lib");
    print "ok 5\n";
}

package One::Two;

use Cwd qw(getcwd);
use rlib;
use File::Basename qw(dirname);

BEGIN {
    my $cwd = dirname(File::Spec->catdir(getcwd(),"t"));

    print "not " unless $INC[0] eq File::Spec->catdir($cwd,"../lib");
    print "ok 6\n";

    print "not " unless $INC[1] eq File::Spec->catdir($cwd,"lib");
    print "ok 7\n";
}
