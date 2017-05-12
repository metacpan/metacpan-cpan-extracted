# _ can start a name (ie an element name or an attribute name)

use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..2\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    parsefile("_TINY_XML_STRING_<_x>\n</_x>"),
    [{ 'name' => '_x', 'content' => [], 'type' => 'e', attrib => {} }],
    "names can start with underscore"
);
is_deeply(
    parsefile("_TINY_XML_STRING_<_x _attrib='hlagh'>\n</_x>"),
    [{
      'name'    => '_x',
      'content' => [],
      'type'    => 'e',
      'attrib'  => { '_attrib' => 'hlagh' }
    }],
    "... in attributes as well as elements"
);
