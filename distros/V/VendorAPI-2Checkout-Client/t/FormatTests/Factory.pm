package FormatTests::Factory;

use FormatTests::XML;
use FormatTests::JSON;

use strict;
use warnings;

sub get_format_tests {
   my $class = shift;
   my $format = shift|| 'XML';

   my $testclass = "FormatTests::$format";
   return $testclass->new();
}



1;
