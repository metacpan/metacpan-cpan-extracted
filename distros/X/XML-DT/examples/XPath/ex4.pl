#!/usr/bin/perl
use XML::DT ;
my $filename = 'ex4.xml';

# tests atribute with name

%handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{ ""},
#     'ccc' => sub{"$q:$c"},
     '//*[@id]' => sub{print "$c\n";toxml},
#     'ddd' => sub{"$q:$c"},
#     'bbb' => sub{"$q:$c"},
#     'eee' => sub{"$q:$c"},
);
pathdt($filename,%handler);
print "\n";
