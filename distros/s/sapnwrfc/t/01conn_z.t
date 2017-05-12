use Test::More tests => 201;

use_ok("sapnwrfc");

# loading from config file
print STDERR  "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;
foreach (1..50) {
    my $conn = SAPNW::Rfc->rfc_connect;
    ok($conn);
    ok($conn->disconnect);
}

# using dynamic config
my $file = 'sap.yml';
open(YML, "<$file") || fail("Cannot open RFC config: $file\n");
my $data = join("", (<YML>));
close(YML);
my $config;
eval { $config = YAML::Load($data); };
fail("config: ".$@) if $@;
SAPNW::Rfc->unload_config;
foreach (1..50) {
    my $conn = SAPNW::Rfc->rfc_connect(%$config);
    ok($conn);
    ok($conn->disconnect);
}
    