use Test;
BEGIN { plan tests => 2 }
use XML::LibRSVG;

my $rsvg = XML::LibRSVG->new();
ok($rsvg);
$rsvg->write_png_from_file("testfiles/computer.svg" => "/tmp/xml-librsvg.png");
ok(unlink("/tmp/xml-librsvg.png"));

