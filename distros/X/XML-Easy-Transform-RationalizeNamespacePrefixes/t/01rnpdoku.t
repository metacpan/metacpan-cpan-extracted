#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::XML::Easy;

use XML::Easy::Text qw(xml10_read_document xml10_write_element);
use XML::Easy::Transform::RationalizeNamespacePrefixes qw(
   rationalize_namespace_prefixes
);

sub process($) {
  return rationalize_namespace_prefixes(
    xml10_read_document( $_[0] )
  ),
}

sub chompp($) {
  my $thingy = shift;
  chomp $thingy;
  return $thingy;
}

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "move up"};
<foo>
  <ex1:bar xmlns:ex1="http://www.photobox.com/namespace/example1" />
</foo>
XML
<foo xmlns:ex1="http://www.photobox.com/namespace/example1">
  <ex1:bar/>
</foo>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "default"};
<foo>
  <bar xmlns="http://www.photobox.com/namespace/example1">
    <bazz zing="zang">
      <buzz xmlns="http://www.photobox.com/namespace/example2"/>
    </bazz>
  </bar>
</foo>
XML
<foo xmlns:default2="http://www.photobox.com/namespace/example1" xmlns:default3="http://www.photobox.com/namespace/example2">
  <default2:bar>
    <default2:bazz zing="zang">
      <default3:buzz/>
    </default2:bazz>
  </default2:bar>
</foo>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "muppet"};
<muppet:kermit xmlns:muppet="http://www.photobox.com/namespace/example/muppetshow" >
  <muppet:kermit xmlns:muppet="http://www.photobox.com/namespace/example/seasmestreet"/>
</muppet:kermit>
XML
<muppet:kermit xmlns:muppet="http://www.photobox.com/namespace/example/muppetshow" xmlns:muppet2="http://www.photobox.com/namespace/example/seasmestreet">
  <muppet2:kermit/>
</muppet:kermit>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "lost attribute prefix"};
<wobble xmlns:ex1="http://www.twoshortplanks.com/namespace/example/1" xmlns:ex1also="http://www.twoshortplanks.com/namespace/example/1">
  <ex1:wibble ex1:jelly="in my tummy" ex1also:yum="yum yum"/>
</wobble>
XML
<wobble xmlns:ex1="http://www.twoshortplanks.com/namespace/example/1">
  <ex1:wibble jelly="in my tummy" yum="yum yum"/>
</wobble>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "no prefix in on attribute in src"};
<a xmlns:ex1="http://www.twoshortplanks.com/namespaces/example/1" xmlns:ex1also="http://www.twoshortplanks.com/namespaces/example/1">
  <ex1:b local="for local people" ex1also:alsolocal="as well"/>
</a>
XML
<a xmlns:ex1="http://www.twoshortplanks.com/namespaces/example/1">
  <ex1:b alsolocal="as well" local="for local people"/>
</a>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "no default till later"};
<ex1:a xmlns:ex1="http://www.twoshortplanks.com/namespaces/example/1">
  <b xmlns="http://www.twoshortplanks.com/namespaces/example/2"/>
</ex1:a>
XML
<ex1:a xmlns="http://www.twoshortplanks.com/namespaces/example/2" xmlns:ex1="http://www.twoshortplanks.com/namespaces/example/1">
  <b/>
</ex1:a>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "multiple prefixes => 1 prefix"};
<a>
  <ex3:c xmlns:ex3="http://www.twoshortplanks.com/namespaces/example/3">
     <ex3also:c xmlns:ex3also="http://www.twoshortplanks.com/namespaces/example/3"/>
  </ex3:c>
  <ex3alsoalso:c xmlns:ex3alsoalso="http://www.twoshortplanks.com/namespaces/example/3"/>
</a>
XML
<a xmlns:ex3="http://www.twoshortplanks.com/namespaces/example/3">
  <ex3:c>
     <ex3:c/>
  </ex3:c>
  <ex3:c/>
</a>
XML

is_xml process <<'XML', <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "multiple overloaded prefixes"};
<a>
  <ns:b xmlns:ns="http://www.twoshortplanks.com/namespaces/example/1">
     <ns:c xmlns:ns="http://www.twoshortplanks.com/namespaces/example/2">
       <ns:d />
     </ns:c>
  </ns:b>
  <ns:e xmlns:ns="http://www.twoshortplanks.com/namespaces/example/3"/>
</a>
XML
<a xmlns:ns="http://www.twoshortplanks.com/namespaces/example/1" xmlns:ns2="http://www.twoshortplanks.com/namespaces/example/2" xmlns:ns3="http://www.twoshortplanks.com/namespaces/example/3">
  <ns:b>
     <ns2:c>
       <ns2:d/>
     </ns2:c>
  </ns:b>
  <ns3:e/>
</a>
XML

is_xml rationalize_namespace_prefixes(xml10_read_document(<<'XML'), { namespaces => { 'http://www.twoshortplanks.com/namespaces/example/1' => "zippy"} }), <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "forced prefix"};
<a>
  <ns:b xmlns:ns="http://www.twoshortplanks.com/namespaces/example/1">
     <ns:c xmlns:ns="http://www.twoshortplanks.com/namespaces/example/2">
       <ns:d />
     </ns:c>
  </ns:b>
  <ns:e xmlns:ns="http://www.twoshortplanks.com/namespaces/example/3"/>
</a>
XML
<a xmlns:zippy="http://www.twoshortplanks.com/namespaces/example/1" xmlns:ns="http://www.twoshortplanks.com/namespaces/example/2" xmlns:ns2="http://www.twoshortplanks.com/namespaces/example/3">
  <zippy:b>
     <ns:c>
       <ns:d/>
     </ns:c>
  </zippy:b>
  <ns2:e/>
</a>
XML

is_xml rationalize_namespace_prefixes(xml10_read_document(<<'XML'), { force_attribute_prefix => 1 }), <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "forced attribute prefix"};
<doc xmlns:muppetshow="http://www.twoshortplanks.com/namespaces/example/muppetshow" xmlns:sesamestreet="http://www.twoshortplanks.com/namespaces/example/sesamestreet">
  <sesamestreet:cast burt="1" ernie="1" muppetshow:kermit="1" />
</doc>
XML
<doc xmlns:muppetshow="http://www.twoshortplanks.com/namespaces/example/muppetshow" xmlns:sesamestreet="http://www.twoshortplanks.com/namespaces/example/sesamestreet">
  <sesamestreet:cast sesamestreet:burt="1" sesamestreet:ernie="1" muppetshow:kermit="1" />
</doc>
XML

is_xml rationalize_namespace_prefixes(xml10_read_document(<<'XML'), { force_attribute_prefix => 1 }), <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "forced attribute prefix 2"};
<doc foo="1" bar="2" />
XML
<doc foo="1" bar="2" />
XML

is_xml rationalize_namespace_prefixes(xml10_read_document(<<'XML')), <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "non-default namespace repeated" };
<ns1:a xmlns:ns1="http://example.org/ns/1">
  <ns2:b xmlns:ns2="http://example.org/ns/1"/>
</ns1:a>
XML
<ns1:a xmlns:ns1="http://example.org/ns/1">
  <ns1:b/>
</ns1:a>
XML

is_xml rationalize_namespace_prefixes(xml10_read_document(<<'XML')), <<'XML', { show_xml => 1, ignore_whitespace => 1, description => "default namespace repeated" };
<a xmlns="http://example.org/ns/1">
  <ns:b xmlns:ns="http://example.org/ns/1"/>
</a>
XML
<a xmlns="http://example.org/ns/1">
  <b/>
</a>
XML

########################################################################
# error cases
########################################################################

eval {
  process <<'XML'
<bar xmlns::foo="bad ns"/>
XML
};
like($@, qr/Specification violation: Can't have more than one colon in attribute name 'xmlns::foo'/, "bang - attr name 1/3");

eval {
  process <<'XML'
<bar xmlns:fo:o="bad ns"/>
XML
};
like($@, qr/Specification violation: Can't have more than one colon in attribute name 'xmlns:fo:o'/, "bang - attr name 2/3");

eval {
  process <<'XML'
<bar xmlns:foo:="bad ns"/>
XML
};
like($@, qr/Specification violation: Can't have more than one colon in attribute name 'xmlns:foo:'/, "bang - attr name 3/3");


eval {
  process <<'XML'
<bar xmlns:xmlns="something else"/>
XML
};
like($@, qr/Specification violation: Can't assign any namespace to prefix 'xmlns'/, "bang - xmlns prefix");

eval {
  process <<'XML'
<bar xmlns:xml="something else"/>
XML
};
like($@, qr/Specification violation: Can't assign 'something else' to prefix 'xml'/, "bang - xml prefix");

eval {
  process <<'XML'
<bar xmlns:something="http://www.w3.org/2000/xmlns/"/>
XML
};
like($@, qr{Specification violation: Can't assign 'http://www.w3.org/2000/xmlns/' to any prefix}, "bang - xmlns namespace");


eval {
  process <<'XML'
<bar xmlns:xml="http://www.w3.org/XML/1998/namespace"/>
XML
};
ok(!$@, "no bang - xml ns for xml prefix");

eval {
  process <<'XML'
<foo:bar />
XML
};
like($@, qr/Prefix 'foo' has no registered namespace/, "bang - not reg");
