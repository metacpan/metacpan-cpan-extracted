#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN { use_ok('XML::DOMBacked') };

package Person;

use base 'XML::DOMBacked';

Person->uses_namespace(
		       'foaf' => 'http://xmlns.com/foaf/0.1/',
		      );
Person->uses_namespace( 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' );
Person->has_properties( 'foaf:name','foaf:title','foaf:nick' );
Person->has_attributes( 'rdf:nodeID' );

sub nodename { "foaf:Person" }

package main;

ok( my $p = Person->new );
ok( $p->nodeID("me") );
ok( $p->name('A. N. Other') );
ok( $p->title('Mr') );
ok( $p->nick('another') );

ok( my $f = Person->from_uri( 'file:t/person.xml' ) );
is( $f->title, $p->title );
is( $f->nick, $p->nick );
is( $f->name, $p->name );
is( $f->nodeID, $p->nodeID );
is( $p->as_xml, $f->as_xml );

#print $f->as_xml;
#print $p->as_xml;

