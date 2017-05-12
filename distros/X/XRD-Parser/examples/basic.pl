use XRD::Parser;
use RDF::Trine::Serializer::NTriples;

my $xrd = <<XRD;
<foo xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0" 
  xmlns:h="http://host-meta.net/ns/1.0">
<XRD>
  <Expires>1970-01-01T00:00:00Z</Expires>
  <h:Host>example.com</h:Host>
  <h:Host>www.example.com</h:Host>
  <Link rel="profile" template="http://services.example.com/profile?uri={uri}">
    <Property type="http://property.example.net/1">Foo</Property>
    <Property type="http://property.example.net/2">Bar</Property>
  </Link>
  <Property type="http://property.example.net/3">Baz</Property>
  <Link rel="another" href="/target" type="text/plain">
    <Title>Another</Title>
    <Property type="http://property.example.net/4">Quux</Property>
  </Link>
</XRD>
<XRD>
  <Subject>http://example.net/</Subject>
  <Expires>1970-02-01T00:00:00Z</Expires>
</XRD>
</foo>
XRD

my $parser = XRD::Parser->new($xrd, "http://example.org/");
$parser->consume;

my $ser = RDF::Trine::Serializer::NTriples->new;
print $ser->serialize_model_to_string($parser->graph);
