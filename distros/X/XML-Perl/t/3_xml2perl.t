use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/..";

use Test::More tests => 2;

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

my $new_xml = perlbase2xml($t, 0, "\t", "\n");

is $new_xml, $xml, "xml2perl";
