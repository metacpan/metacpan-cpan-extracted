use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/..";

use Test::More tests => 7;

BEGIN { use_ok( 'XML::Perl' ); }


my $xml = <<EOD;
<a f="foo">
	<aa a="b">11</aa>
	<ab a="1">12</ab>
	<ab a="2">13</ab>
</a>
<b>
	<c>4</c>
	<d>5</d>
</b>
<b>
	<c>6</c>
	<d>7</d>
</b>
EOD


my $t = xml2perlbase($xml);



sub xpath_test {
	my ($t, $path, $expected) = @_;
	my $r = join ", ", xpath($t, $path);
	# print "$path = $r\n";
	is $r, $expected, $path;
}


xpath_test($t, '/a/ab',       '12, 13');
xpath_test($t, '/b/c',        '4, 6');
xpath_test($t, '/b[2]/c',     '6');
xpath_test($t, '/a/ab[2]/@a', '2');


{
my $xpath = '/b[2]';
my $expected = <<EOD;
<c>6</c>
<d>7</d>
EOD
my $nt = xpath($t, $xpath);
is perlbase2xml($nt), $expected, $xpath;
}


xpath_test($t, 'ab', '12, 13');
