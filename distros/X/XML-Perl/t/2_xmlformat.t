use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/..";

use Test::More tests => 2;

BEGIN { use_ok( 'XML::Perl' ); }


my $xml = '<?xml version=\'1.0\'?><test><data attr1="test">some test text</data><empty a="b"><inner c="d"/></empty><private some="value"/><censored foo="secret"/><array perl="awesome" hidden="secret"><item index="0"/><item index="1"/><item index="2"/></array></test>';


chomp (my $xmlformat = <<EOD);
<?xml version='1.0'?>
<test>
	<data attr1="test">some test text</data>
	<empty a="b">
		<inner c="d"/>
	</empty>
	<private some="value"/>
	<censored foo="secret"/>
	<array perl="awesome" hidden="secret">
		<item index="0"/>
		<item index="1"/>
		<item index="2"/>
	</array>
</test>
EOD

is xmlformat($xml), $xmlformat, "xmlformat";
