#!/usr/bin/perl

use strict;
use warnings;
use Test::XML::Compare tests => 3;

my $tests = [
   {
       name => 'Simple CDATA Section',
       xml1 => '<foo>Blah</foo>',
       xml2 => '<foo><![CDATA[Blah]]></foo>',
   },
   {
       name => 'CDATA and Text Section',
       xml1 => '<foo>Blah and Blah</foo>',
       xml2 => '<foo><![CDATA[Blah]]> and Blah</foo>',
   },
   {
       name => 'Mish-mash of Text and CDATA Section',
       xml1 => '<foo><![CDATA[Blah]]>, Blah <![CDATA[and]]> <![CDATA[ Blah]]></foo>',
       xml2 => '<foo>Blah, <![CDATA[Blah]]> <![CDATA[ and Blah]]></foo>',
   },
];

foreach my $t ( @$tests ) {
    is_xml_same($t->{xml1}, $t->{xml2}, $t->{name});
}
