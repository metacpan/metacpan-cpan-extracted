#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Builder::Tester;
use Test::XML::Easy;

is_xml(<<'ENDOFXML',<<'ENDOFXML2', { description => "it works"});
<foo>
  This is some text blah blah blah
  <flintstones fred="wilma" barney="betty" />
  <bar name="quark's" />
  <bar name="cheers" />
  <zippy>
    <rod/>
    jane
    <freddy>are dancers</freddy>
  </zippy>
</foo>
ENDOFXML
<foo>
  This is some text blah blah blah
  <flintstones fred="wilma" barney="betty"      />
  <bar name="quark's" />
  <bar name="cheers"></bar>
  <zippy>
    <rod/>
    jane
    <freddy>are dancers</freddy>
  </zippy>
</foo>
ENDOFXML2

