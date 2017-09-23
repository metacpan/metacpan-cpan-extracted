package Whatever;

BEGIN {
    $main::FILE = __FILE__;
    $main::FILE =~ s/goto_ending\.t/ending.t/;
    print "# goto $main::FILE\n";
}

use goto::file $main::FILE;

die "Should not get here!";
