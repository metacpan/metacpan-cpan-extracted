# Need to suppress warinings ?
BEGIN { $^W = 0; $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use sapnwrfc;
$loaded = 1;
print "ok 1\n";                                                                                     
print "Testing sapnwrfc-$sapnwrfc::VERSION\n";

SAPNW::Rfc->load_config;
my $conn = SAPNW::Rfc->rfc_connect;

print $conn->disconnect ? "ok 2" : "not ok 2", "\n";

