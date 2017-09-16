package Whatever;

BEGIN {
    $main::FILE = __FILE__;
    $main::FILE =~ s/goto_data\.t/data.t/;
    print "# goto $main::FILE\n";
}

use goto::file $main::FILE;

die "Should not get here!";

__DATA__

This is bad data!
