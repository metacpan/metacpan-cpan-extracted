#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use XML::Compare;

# $XML::Compare::VERBOSE = 1;

my $same = [
   {
       name => 'Basic',
       xml1 => '<foo></foo>',
       xml2 => '<foo></foo>',
   },
   {
       name => 'Basic with TextNode',
       xml1 => '<foo>Hello, World!</foo>',
       xml2 => '<foo>Hello, World!</foo>',
   },
   {
       name => 'Basic with NS',
       xml1 => '<foo xmlns="urn:foo"></foo>',
       xml2 => '<f:foo xmlns:f="urn:foo"></f:foo>',
   },
   {
       name => 'Basic with implied NS',
       xml1 => '<foo></foo>',
       xml2 => '<f:foo xmlns:f="urn:foo"></f:foo>',
       args => [ namespace_strict => 0 ],
   },
   {
       name => 'Same Attributes',
       xml1 => '<foo foo="bar" baz="buz"></foo>',
       xml2 => '<foo baz="buz" foo="bar"></foo>',
   },
   {
       name => 'Empty xmlns',
       xml1 => '<foo xmlns=""></foo>',
       xml2 => '<foo ></foo>',
   },
   {
       name => 'Empty xmlns in lower element',
       xml1 => '<foo xmlns="uri:a"><nothing xmlns="" /></foo>',
       xml2 => '<a:foo xmlns:a="uri:a"><nothing xmlns="" /></a:foo>',
   },
   {
       name => 'Whitespace ambivalent',
       xml1 => '<foo xmlns="uri:a"><nothing xmlns="" /></foo>',
       xml2 => '<a:foo xmlns:a="uri:a">
   <nothing xmlns="">&#x20;
</nothing>   </a:foo>',
   },
   {
       name => 'Different Attributes (but ignored)',
       xml1 => '<foo foo="bar"></foo>',
       xml2 => '<foo foo="bar" bar="bar"></foo>',
       msg => qr/attr\w* list length\w* differ\w*/i,
       args => [ ignore => [qw( /foo/@bar )] ],
   },
   {
       name => 'Ignoring namespace-qualified elements',
       xml1 => '<foo xmlns="uri:a"><gay:bar xmlns:gay="uri:gay">Bush</gay:bar></foo>',
       xml2 => '<war:foo xmlns:war="uri:a"><nuclear:bar xmlns:nuclear="uri:gay">Blair</nuclear:bar></war:foo>',
       args => [
	       ignore => [qw( /a:foo/b:bar/text() )],
	       ignore_xmlns => {
		       a => "uri:a",
		       b => "uri:gay",
	       },
	      ],
   },
];

my $diff = [
   {
       name => 'Different Attributes',
       xml1 => '<foo foo="bar"></foo>',
       xml2 => '<foo baz="buz"></foo>',
       msg => qr{at /foo/\@foo\]: attr\w* node value\w* differ\w*}i,  # XXX - this is a bad error
   },
   {
       name => 'Different Attributes',
       xml1 => '<foo foo="bar"></foo>',
       xml2 => '<foo foo="bar" bar="bar"></foo>',
       msg => qr{at /foo\]: attr\w* list length\w* differ\w*}i,
   },
   {
       name => 'Different Attribute value',
       xml1 => '<bar foo="bat"></bar>',
       xml2 => '<bar foo="bar"></bar>',
       msg => qr{at /bar/\@foo\]: attr\w* node value\w* differ\w*}i,
   },
   {
       name => 'Different element',
       xml1 => '<bar foo="bar"></bar>',
       xml2 => '<foo foo="bar"></foo>',
       msg => qr{at /bar\]: node\w* name\w .*differ\w*}i,
   },
   {
       name => 'Different node type',
       xml1 => '<foo foo="bar"><baz/></foo>',
       xml2 => '<foo foo="bar">Hello</foo>',
       msg => qr{at /foo/baz\]: node\w* type\w .*differ\w*}i,
   },
   {
       name => 'Empty xmlns in lower element (not same)',
       xml1 => '<foo xmlns="uri:a"><nothing /></foo>',
       xml2 => '<foo xmlns="uri:a"><nothing xmlns="" /></foo>',
       msg => qr{at /foo/nothing\]: namespaceURI.*defined}i,
   },
   {
       name => 'Basic with implied NS - but strict',
       xml1 => '<foo></foo>',
       xml2 => '<f:foo xmlns:f="urn:foo"></f:foo>',
       args => [ namespace_strict => 1 ],
       msg => qr{at /foo\]: namespaceURI.*defined}i,
   },
   {
       name => 'Empty xmlns in lower element',
       xml1 => '<foo xmlns="uri:a"><nothing xmlfoo="" /></foo>',
       xml2 => '<a:foo xmlns:a="uri:a"><nothing a:xmlfoo="" /></a:foo>',
       msg => qr{at /foo/nothing\]: namespaceURI.*defined.*uri:a}i,
   },
   {
       name => 'Empty xmlns in upper element',
       xml1 => '<a:foo xmlns:a="uri:a"><nothing a:xmlfoo="" /></a:foo>',
       xml2 => '<foo xmlns="uri:a"><nothing xmlfoo="" /></foo>',
       msg => qr{at /a:foo/nothing/\@xmlfoo\]: namespaceURI.*defined.*uri:a}i,
   },
   {
       name => 'TextNode differs',
       xml1 => '<foo>Hello, world!</foo>',
       xml2 => '<foo>Hello, World!</foo>',
       msg => qr{at /foo/text\(\)\]: data.*diff}i,
       #args => [ ignore => [qw[text()]] ],
   },
];

foreach my $t ( @$same ) {
    my $xml_c = XML::Compare->new( @{ $t->{args} || [] } );
    ok( $xml_c->is_same($t->{xml1}, $t->{xml2}), $t->{name} )
	    or diag($xml_c->error);
}

foreach my $t ( @$diff ) {
    my $xml_c = XML::Compare->new( @{ $t->{args} || [] } );
    ok( $xml_c->is_different($t->{xml1}, $t->{xml2}), $t->{name} );
    my $err = $@;
    if ($t->{msg}) {
	like($err, $t->{msg}, "$t->{name} exception");
    }
}
