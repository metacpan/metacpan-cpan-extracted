#!/usr/bin/perl
use XML::DT ;
my $filename = 'ex5.xml';

# tests if exist @* atribute or not(@*)

%handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{ ""},
#     'ccc' => sub{"$q:$c"},
     '//*[not(@*)]' => sub{print "$c\n";toxml},
#     'ddd' => sub{"$q:$c"},
#     'bbb' => sub{"$q:$c"},
#     'eee' => sub{"$q:$c"},
);
pathdt($filename,%handler);
print "\n";
