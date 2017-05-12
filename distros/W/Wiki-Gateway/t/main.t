BEGIN {
	push(@INC, './t');
}

use Test::Unit::HarnessUnit;	
my $r = Test::Unit::HarnessUnit->new();
$r->start('testWikiGatewayDuringInstall.pm');

