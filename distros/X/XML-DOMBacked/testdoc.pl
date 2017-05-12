use lib 'lib';

package Person;

use base 'XML::DOMBacked';

Person->uses_namespace(
		       'foaf' => 'http://xmlns.com/foaf/0.1/',
		       'rdf'  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
		      );
Person->has_properties( 'foaf:name','foaf:title','foaf:nick' );
Person->has_attributes( 'rdf:nodeID' );
Person->has_a( 'Person::Knows' );

sub nodename { "foaf:Person" }

package Person::Knows;

use base 'XML::DOMBacked';
Person::Knows->uses_namespace( foaf => 'http://xmlns.com/foaf/0.1' );
Person::Knows->has_many( people => { class => 'Person' } );

sub nodename { 'foaf:Knows' }

package main;

my $p = Person->new;
$p->nodeID("me");
$p->name('A. N. Other');
$p->title('Mr');
$p->nick('another');

my $james = Person->new->name('James Duncan' );
$james->nodeID('james');
$p->Knows()->add_Person( $james );


print $p->as_xml;

