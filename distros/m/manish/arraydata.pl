#!/usr/bin/perl -w

print "enter the number of elements in array ##\n";
chomp($tt=<STDIN>);
print "enter the elements in array --\n";
#@array=chomp(<STDIN>);
$count=1;
while($count <= $tt)
{
while(defined($arr=<STDIN>))
{

push(@array,$arr);
last;
  }
#@array = push($array[$count-1]);
$count++;
}
#@array = (1,"soso",55);
#$count=1;
#while($count < 4)
#{
#print "elements are $array[$count-1] \n";
#$count++;
#}
#foreach $filee (@array)
#{
#print "$filee \n" ;
#}
#@array = (1,"soso",55);
$count=1;
$sum=0;
while($count <= $tt)
{
#print "elements are $array[$count-1] \n";
$sum=$sum + $array[$count-1];
$count++;
}
print "elements summation is $sum\n";
