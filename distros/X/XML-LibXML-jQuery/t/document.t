#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;
use Data::Dumper;


my $doc1 = j('<div/>');

isa_ok $doc1->document->get(0), 'XML::LibXML::Document';
is $doc1->{document}->unique_key, $doc1->document->get(0)->unique_key;


done_testing;
