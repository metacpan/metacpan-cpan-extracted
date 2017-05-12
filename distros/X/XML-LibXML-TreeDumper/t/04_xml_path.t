#!/usr/bin/env perl

use strict;
use warnings;

use XML::LibXML::TreeDumper;
use Test::More;

my $dumper = XML::LibXML::TreeDumper->new;
isa_ok $dumper, 'XML::LibXML::TreeDumper';

my $xml = <<XML;
<test>
  <string>hallo</string>
</test>
XML

$dumper->data( \$xml );
is ${ $dumper->data }, $xml;

my $check = qq~XML::LibXML::Element         string
    XML::LibXML::Text         "hallo"
~;
is $dumper->dump('/test/string'), $check;

done_testing();
