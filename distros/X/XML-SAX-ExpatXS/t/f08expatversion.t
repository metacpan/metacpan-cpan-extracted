# Provided by Axel Eckenberger, Nov 3, 2005

use Test;
BEGIN { plan tests => 1 }
use XML::SAX::ExpatXS;

my $handler = TestH->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler);

###################### Test 1 ######################
# Looking for Expat version

my $ev = $parser->{ExpatVersion};
#print "ExpatVersion: $ev\n";

ok( $ev =~ /^expat_[\d\.]+$/);


package TestH;
#use Devel::Peek;

sub new { bless {data => ''}, shift }
