$|++; 
print "1..1\n";
my($test) = 1;

# 1 load
use XML::API;
my $loaded = new XML::API(doctype => 'WiX2', encoding => 'UTF-8');
$loaded ? print "ok $test\n" : print "not ok $test\n";
$test++;

