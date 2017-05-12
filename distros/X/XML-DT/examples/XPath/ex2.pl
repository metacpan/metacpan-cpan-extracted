#!/usr/bin/perl
use lib qw(../..);
use XML::DT ;
my $filename = 'ex2.xml';

# pending paths

%handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{"<$q>$c</$q>"},
#     'ccc' => sub{"$q:$c"},
     '//ddd/bbb' => sub{print "$c";toxml},
#     'ddd' => sub{"$q:$c"},
#     'bbb' => sub{"$q:$c"},
#     'eee' => sub{"$q:$c"},
);
pathdt($filename,%handler); 
print "\n";
