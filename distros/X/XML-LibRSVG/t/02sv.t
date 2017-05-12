use Test;
BEGIN { plan tests => 2 }
use XML::LibRSVG;

my $rsvg = XML::LibRSVG->new();
ok($rsvg);
ok($rsvg->png_from_file("testfiles/computer.svg"));

