use strict;

use Test::More tests => 2;
use XML::FOAF;

my $rdf = <<'FOAF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE foo [
  <!ENTITY ref SYSTEM "file:///etc/passwd">
]>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:foaf="http://xmlns.com/foaf/0.1/">
<foaf:Person>
<foaf:name>/etc/passwd:&ref;eof</foaf:name>
</foaf:Person>
</rdf:RDF>
FOAF

my $foaf = XML::FOAF->new(\$rdf);
is(ref $foaf, 'XML::FOAF');
is($foaf->person->name, '/etc/passwd:eof');
