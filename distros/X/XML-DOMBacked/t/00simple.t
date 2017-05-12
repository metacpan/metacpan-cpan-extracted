#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;

BEGIN { use_ok('XML::DOMBacked') };

package Foo;

use base 'XML::DOMBacked';

Foo->uses_namespace( foo => 'http://www.foo.com' );
Foo->uses_namespace( 'BAR' => 'http://www.bar.com' );
Foo->has_properties( 'name', 'foo:size' );
Foo->has_attributes( 'uri', 'foo:id' );
Foo->has_a( 'Bar', 'Baz' );

package Bar;

use base 'Foo';

Bar->uses_namespace( 'BAR' => 'http://www.bar.com' );
Bar->has_properties( 'BAR:age' );

sub nodename { 'BAR:bar' }

package Baz;

use base 'XML::DOMBacked';

Baz->uses_namespace( test => 'http://www.fotango.com' );
Baz->has_many( 'bars' => { class => 'Bar' }, names => 'test:name' );

package main;

ok( my $f = Foo->new );
ok( my $b = Bar->new );

ok( my $ns = Foo->lookup_namespace( 'foo' ) );
is( $ns, 'http://www.foo.com' );
is( $f->lookup_namespace( 'foo' ), 'http://www.foo.com' );
is( $b->lookup_namespace( 'BAR' ), 'http://www.bar.com' );

isa_ok( $b, 'Bar' );
isa_ok( $b, 'Foo' );
is( $b->lookup_namespace( 'foo' ), 'http://www.foo.com' );

ok( $f->name( 'test' ) );
is( $f->name, 'test', "name is test" );

ok( $f->size( 'large' ) );
is( $f->size, 'large', 'namespaced properties work' );


#print $f->as_xml;

#exit;

ok( $b->size( 'small' ) );
ok( $b->age( 26 ) );
ok( $b->uri( 'http://www.fotango.com/thisBar' ) );
is( $b->uri, 'http://www.fotango.com/thisBar', "attributes work");
ok( $b->id('x102') );
is( $b->id, 'x102', "namespaced attributes work" );

ok( $f->bar( $b ) );

#print $f->bar, "\n";

is( $f->bar->as_string, $b->as_string );

#exit;

ok( my $baz = Baz->new );

ok( $baz->add_name( "James" ) );
ok( $baz->add_name( "Katrien" ) );
ok( my @names = $baz->names );
is( scalar(@names), 2, "got two names" );

ok( $baz->remove_name( 'James' ) );
is( scalar( $baz->names ), 1 );

ok( my $metro = Bar->new->name( 'Metro' ) );
ok( my $vibe  = Bar->new->name('Vibe') );
ok( $baz->add_bar( $metro ) );
ok( $baz->add_bar( $vibe ) );
ok( my @bars = $baz->bars() );
is( scalar(@bars), 2 );
is( $bars[0], $metro );
is( $bars[1], $vibe );
ok( $baz->remove_bar( $metro ) );
ok( $baz->remove_bar( $bars[1] ) );
is( scalar($baz->bars), 0, "no more bars" );

ok( $f->Baz( $baz ) );

#print $baz->as_xml;
#print $f->Baz->as_xml;

#print $f->as_xml;

is( $baz, $f->Baz );




1;
