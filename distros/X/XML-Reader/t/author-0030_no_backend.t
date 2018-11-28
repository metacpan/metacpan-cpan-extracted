
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

use Test::More tests => 1;
use File::Temp ('tempdir');

# This test verifies that XML::Reader throws an error at compile time
# if the user doesn't provide a backend module and neither XML::Parser
# nor XML::Parsepp are available.

my $lib;
BEGIN {
    $lib = tempdir ( CLEANUP => 1 );
    mkdir "$lib/XML";
    for my $module (qw(Parser Parsepp)) {
        open (my $fh, '>', "$lib/XML/$module.pm");
        print $fh '0;';
        close $fh;
        -e "$lib/XML/$module.pm"
            or die "Failed to create fake XML::$module";
    }
}
use lib $lib;

eval "use XML::Reader;";
like($@,qr/^Error:/,'No backend gives failure at compile time');
