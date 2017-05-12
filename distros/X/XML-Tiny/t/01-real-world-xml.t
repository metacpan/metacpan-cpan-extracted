use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..2\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    parsefile('t/amazon.xml'),
    do "t/amazon-parsed-with-xml-parser-easytree",
    "Real-world XML from Amazon parsed correctly"
);

is_deeply(
    parsefile('t/rss.xml'),
    do "t/rss-parsed-with-xml-parser-easytree",
    "Real-world XML from an RSS feed parsed correctly"
);
