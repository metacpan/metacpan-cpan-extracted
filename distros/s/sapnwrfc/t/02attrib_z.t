use Test::More tests => 151;

use_ok("sapnwrfc");

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;


foreach (1..50) {
    my $conn = SAPNW::Rfc->rfc_connect;
    my $attrib = $conn->connection_attributes;
    ok($attrib);
    #ok($attrib->{pcs} =~ /^(1|2)$/);
    ok($attrib->{rfcRole} eq 'C');
    ok($conn->disconnect);
}

