# Need to suppress warinings ?
BEGIN { $^W = 0; $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use sapnwrfc;
use Data::Dumper;
$loaded = 1;
print "ok 1\n";                                                                                     

SAPNW::Rfc->load_config;
my $conn = SAPNW::Rfc->rfc_connect;

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
my $attrib = $conn->connection_attributes;
print $attrib ? "ok 2" : "not ok 2", "\n";
print STDERR "attributes: ".Dumper($attrib)."\n";
#print $attrib->{pcs} =~ /^(1|2)$/ ? "ok 3" : "not ok 3", "\n";
print $attrib->{rfcRole} eq 'C' ? "ok 3" : "not ok 3", "\n";
print $conn->disconnect ? "ok 4" : "not ok 4", "\n";

