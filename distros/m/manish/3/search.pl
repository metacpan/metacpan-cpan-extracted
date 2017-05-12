#!/usr/bin/perl -w
#print "enter the image value";
$cnt=0 ;

while(<>)
{
while($_ =~ /\@/g)
{
$cnt=$cnt+1 ;
}
}
print "mail id exist numbers  $cnt \n";


