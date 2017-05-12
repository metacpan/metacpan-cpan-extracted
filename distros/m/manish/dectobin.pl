#!/usr/bin/perl -w
print "please enter your decimal value here --- = ";
chomp($dec=<STDIN>);
$rem=0;
@array;
while($dec >= 2)
{
$rem=$dec%2;
$dec=int($dec/2);
push(@array,"$rem");
}
push(@array,"$dec");

@array = reverse(@array);

print "values are as @array here \n";

