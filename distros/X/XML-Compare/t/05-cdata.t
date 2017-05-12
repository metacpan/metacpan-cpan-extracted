#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use XML::Compare;

# $XML::Compare::VERBOSE = 1;

my $same = [
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

my $diff = [];

foreach my $t ( @$same ) {
    ok( XML::Compare::is_same($t->{xml1}, $t->{xml2}), $t->{name} );
}

foreach my $t ( @$diff ) {
    ok( XML::Compare::is_different($t->{xml1}, $t->{xml2}), $t->{name} );
}
