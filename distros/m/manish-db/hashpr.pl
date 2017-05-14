#!/usr/bin/perl -w
print "content-type: text/html\n\n" ;
use best qw(camel $weight);

&camel;
%hash = qw(
         name  manish
         Age    23 
         country  london

);
while (($key, $value)=each(%hash))
{
print "$key - $value \n"  ;
}

foreach $key (keys %hash)
{
print "$key\n";
}
foreach $value (values %hash)
{
print "$value\n";
}
while (($key, $value)=each(%hash))
{
print "$value - $key \n"  ;
}
print "value is $weight \n";

