# The test is not that html_ok() works, but that the tests=>1 gets
# acts as it should.

use Test::HTML::Tidy tests=>1;

my $filename = "t/clean.html";
open( my $fh, "<", $filename ) or die "Can't open $filename: $!\n";
my $html = do { local $/ = undef; <$fh> };
close $fh;

html_tidy_ok( $html );
