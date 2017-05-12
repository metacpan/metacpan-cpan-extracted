#!perl -T

use Test::More tests => 4;
use XML::Trivial;

my $xmlstr = q{<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<!DOCTYPE html PUBLIC "Public/id" "http://pajout.eu/xml-trivial/test.dtd">
 <root>
   <home>/usr/local/myApplication</home>
   <sections>
     <section name='A' version='1.8' escaped='&apos;,",&lt;'>
       <a_specific>aaa</a_specific>
     </section>
     <section name='B'>bbb</section>
     <text>
     ...and there is another stuff
     <![CDATA[<html><body><hr>Hello, world!<hr></body></html>]]>
     ...more stuff here...
       <element></element>
     <![CDATA[2nd CDATA]]>
     ...]]&gt;...
     </text>
   </sections>
 <!--processing instructions-->
   <?first do something ?>
   <?second do st. else ?>
   <?first fake ?>
 <!--namespaces-->
   <meta xmlns='meta_ns' xmlns:p1='first_ns' xmlns:p2='second_ns'>
     <desc a='v' p1:a='v1' p2:a='v2'/>
     <p1:desc a='v' p1:a='v1' p2:a='v2'/>
     <p2:desc a='v' p1:a='v1' p2:a='v2'/>
   </meta>
 </root>};

my $xml = XML::Trivial::parse($xmlstr);
ok( defined $xml, 'xml doc parsed' );
ok( $xml->sr(), 'xml doc serialized' );

my $xmlstr2 = "<root a='&apos;&apos;'>&lt;&lt;</root>";
my $xml2 = XML::Trivial::parse($xmlstr2);
ok( $xml2->sr() eq $xmlstr2, 'serialized data escaped' );

my $xmlstr3 = XML::Trivial::parse(q{<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<!DOCTYPE html PUBLIC "Public/id" "http://pajout.eu/xml-trivial/test.dtd">
 <root>
   <home>/usr/local/myApplication</home>
   <sections>
     <section escaped='&apos;,",&lt;'>
       <a_specific>aaa</a_specific>
     </section>
     <section name='B'>bbb</section>
     <text>
     ...and there is another stuff
     <![CDATA[<html><body><hr>Hello, world!<hr></body></html>]]>
     ...more stuff here...
       <element></element>
     <![CDATA[2nd CDATA]]>
     ...]]&gt;...
     </text>
   </sections>
 <!--processing instructions-->
   <?first do something ?>
   <?second do st. else ?>
   <?first fake ?>
 </root>})->sr;
my $xmlstr4 = XML::Trivial::parse($xmlstr3)->sr;
ok( $xmlstr3 eq $xmlstr4, 'double serialized equals' );
