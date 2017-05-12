#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use Test::Exception";
  if ($@) {
      Test::More::plan(
          skip_all => "Test::Exception required to test exceptions"
      );
  }
}

use Test::More tests => 3;

use XML::Easy::ProceduralWriter;
use Test::Exception;

########################################################################

throws_ok {
  xml_bytes { 
    element "foo";
    element "bar";
  }
} qr/More than one root node specified/, "more than one root node error";

########################################################################

throws_ok {
  xml_bytes { 
    text "before";
    element "foo";
  }
} qr/Text before root node/, "text before root node";

########################################################################

throws_ok {
  xml_bytes { 
    element "foo";
    text "after";
  }
} qr/Text after root node/, "text after root node";

########################################################################
