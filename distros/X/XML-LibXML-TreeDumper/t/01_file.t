#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Basename;
use XML::LibXML::TreeDumper;
use Test::More;

my $dumper = XML::LibXML::TreeDumper->new;
isa_ok $dumper, 'XML::LibXML::TreeDumper';

my $dir = dirname __FILE__;
my $file = File::Spec->catfile( $dir, 'test.xml' );

$dumper->data( $file );
is $dumper->data, $file;

my $check = qq~XML::LibXML::Element         test
    XML::LibXML::Text         "
  "
    XML::LibXML::Element         string
        XML::LibXML::Text         "hallo"
    XML::LibXML::Text         "
"
~;
is $dumper->dump, $check;

done_testing();
