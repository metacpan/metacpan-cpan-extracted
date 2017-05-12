#!/usr/bin/perl
use lib qw(../..);
use XML::DT ;
my $filename = 'ex1.xml';

# simple complete paths

%handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{"<$q>$c</$q>"},
#     'ccc' => sub{"$q:$c"},
     '/aaa' => sub{print "$c";},
#     'ddd' => sub{"$q:$c"},
#     'bbb' => sub{"$q:$c"},
#     'eee' => sub{"$q:$c"},
);
pathdt($filename,%handler); 
print "\n";
