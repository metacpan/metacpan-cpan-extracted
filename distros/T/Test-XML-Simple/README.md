#Test::XML::Simple

[![Build Status](https://travis-ci.org/joemcmahon/test-xml-simple.svg?branch=master)](https://travis-ci.org/joemcmahon/test-xml-simple)

This module provides a test class which makes it easy to do basic
Test::More style tests on XML input.

```perl
  use Test::XML::Simple test => 5;
  xml_valid $xml, 'Is valid XML';
  xml_node $xml, "/xpath/expression", "specified xpath node is present";
  xml_text_is $xml, '/xpath/expr', "expected value", "specified text present";
  xml_text_like $xml, '/xpath/expr', qr/expected/, "regex text present";
  xml_is_deeply $xml, '/xpath/expr', $xml_fragment, "fragment matches path";
```

##INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

##DEPENDENCIES

This module requires these other modules and libraries:

  Test::Builder
  Test::LongString
  Test::More
  XML::LibXML

You should be able to use this module with any Perl from version 5.8 and above.

##COPYRIGHT AND LICENCE

Copyright (C) 2005-2016 by Yahoo! and Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.
