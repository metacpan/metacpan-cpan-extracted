use Test::Lib;
use Test::WebService::ValidSign;

use WebService::ValidSign::Object::DocumentPackage;
use JSON::XS;


my $document_package = WebService::ValidSign::Object::DocumentPackage->new(
    name => "My first package",
);
isa_ok($document_package, "WebService::ValidSign::Object::DocumentPackage");

my $jsonxs = JSON::XS->new()->allow_blessed->convert_blessed;

my $json = $jsonxs->encode($document_package);

# In the comparison this becomes a JSON::PP::Boolean
my $expect = $document_package->TO_JSON;
$expect->{auto_complete} = ignore();
$expect->{settings} = ignore();

cmp_deeply(
    $jsonxs->decode($json),
    $expect,
    "Encoding/decoding of DocumentPackage works fine"
);

done_testing;
