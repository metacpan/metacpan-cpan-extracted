#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;



my $j = jQuerySubClass->new('<div></div><div class="foo"></div>');

isa_ok $j, 'XML::LibXML::jQuery';
isa_ok $j->find('.foo'), 'jQuerySubClass', 'object returned by find()';

done_testing;


package jQuerySubClass;
use parent 'XML::LibXML::jQuery';
