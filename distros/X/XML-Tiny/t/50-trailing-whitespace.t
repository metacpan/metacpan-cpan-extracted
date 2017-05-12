use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..1\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

# use Data::Dumper;
# die Dumper(parsefile('t/trailing-whitespace-in-tags.xml'));
ok(parsefile('t/trailing-whitespace-in-tags.xml'), "Don't choke on trailing whitespace in tags");
