
use strict;
use warnings;

use Test::More tests => 2;

use XML::Hash::XS qw();

our $conv = XML::Hash::XS->new();
our $xml_decl = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        $conv->hash2xml( { node1 => sub { 'value1' } } ),
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'code reference',
    ;
}

{
    is
        XML::Hash::XS::hash2xml( { node1 => sub { 'value1' } } ),
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'code reference',
    ;
}
