#!/usr/bin/perl -w
#use strict;
unshift(@INC, "/manish-scripts/");
my @array;
require("don.pl");

#print "enter the numbers to add # \n";
#chomp($tt=<STDIN>);
$count=1;
while($count < 3)
{
while(defined($arr=<STDIN>))
{
push(@array,$arr);
last;
}
$count++;
}
$val=&sum;
print "value are $val ";
