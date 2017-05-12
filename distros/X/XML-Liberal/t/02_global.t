use strict;
use Test::More 'no_plan';

use FindBin;
use XML::LibXML;
use XML::Liberal;

XML::Liberal->globally_override('LibXML');

my $data = "$FindBin::Bin/bad";

opendir D, $data;
for my $f (readdir D) {
    next unless $f =~ /\.xml$/;
    next if $f =~ /chr|lowascii/;

    my $parser = XML::LibXML->new;
    my $doc = eval { $parser->parse_file("$data/$f") };
    is $@, '', "$data/$f";
    isa_ok $doc, 'XML::LibXML::Document', "created DOM node with $data/$f";

    $parser = XML::LibXML->new;
    $parser->recover(1);
    $doc = eval { $parser->parse_file("$data/$f") };
    is $@, '', "$data/$f";
    isa_ok $doc, 'XML::LibXML::Document', "created DOM node with $data/$f";

    $parser = XML::Liberal->new('LibXML');
    $doc = eval { $parser->parse_file("$data/$f") };
    is $@, '', "$data/$f";
    isa_ok $doc, 'XML::LibXML::Document', "created DOM node with $data/$f";
}

