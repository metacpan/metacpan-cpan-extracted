# -*- perl -*-

BEGIN {
    $| = 1;
    print "1..2\n";
    $0 = "savevarstest";
}

use savevars;

my $cfgfile = savevars::cfgfile();

if (!-e $cfgfile) {
    print "not ";
}
print "ok 1\n";

unlink $cfgfile;
if (-e $cfgfile) {
    print "not ";
}
print "ok 2\n";

savevars::dont_write_cfgfile();
