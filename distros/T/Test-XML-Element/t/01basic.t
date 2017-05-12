#!/usr/bin/perl
use Test::More tests => 4;
BEGIN { use_ok 'Test::XML::Element' };

element_is('<foobar />', 'foobar');
has_attribute('<foobar color="red" />', 'color');
attribute_is('<foobar color="red" />', color => 'red');
