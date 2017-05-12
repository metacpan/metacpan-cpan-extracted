#!/usr/bin/perl
use XML::DT ;
my $filename = 'ex3.xml';

# Paths containing *

%handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{ ""},
#     'ccc' => sub{"$q:$c"},
     '//*/*/bbb' => sub{print "$c\n";toxml},
#     'ddd' => sub{"$q:$c"},
#     'bbb' => sub{"$q:$c"},
#     'eee' => sub{"$q:$c"},
);
pathdt($filename,%handler);
print "\n";
