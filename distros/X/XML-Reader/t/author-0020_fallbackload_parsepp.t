
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

use Test::More tests => 2;
use File::Temp ('tempdir');

# This test verifies that XML::Reader uses XML::Parsepp as fallback if
# the user doesn't provide a backend module and XML::Parser is not
# available.

my $lib;
BEGIN {
    $lib = tempdir ( CLEANUP => 1 );
    mkdir "$lib/XML";
    open (my $fh, '>', "$lib/XML/Parser.pm");
    print $fh '0;';
    close $fh;
    -e "$lib/XML/Parser.pm"
        or die "Failed to create fake XML::Parser";
}
use lib $lib;

use XML::Reader; # no specification of a backend

ok($INC{'XML/Parsepp.pm'},'XML::Parsepp is used as a backend');
ok(! exists $INC{'XML/Parser.pm'}, 'XML::Parser is not used');
